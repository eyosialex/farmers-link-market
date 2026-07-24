// ══════════════════════════════════════════════════════════════════════
//   LINKEDFARM ELITE COMMAND — script.js
// ══════════════════════════════════════════════════════════════════════

const firebaseConfig = {
    apiKey: "AIzaSyD_u-CbOyvERFhtNl9dTHSOsNCsTV9TMgc",
    appId: "1:447095155412:web:656a232313e4f5ed5ba941",
    messagingSenderId: "447095155412",
    projectId: "eyyosi",
    authDomain: "eyyosi.firebaseapp.com",
    databaseURL: "https://eyyosi-default-rtdb.firebaseio.com",
    storageBucket: "eyyosi.firebasestorage.app",
    measurementId: "G-LF6J4ZMH2B",
};

if (!firebase.apps.length) firebase.initializeApp(firebaseConfig);
const db = firebase.firestore();

let listeners = {};
let currentUsers = [];
let currentProducts = [];
let isShowingJson = false;

document.addEventListener('DOMContentLoaded', () => {
    // ── Navigation Logic
    const navItems = document.querySelectorAll('.nav-links li');
    const sections = document.querySelectorAll('.page-section');

    navItems.forEach(item => {
        item.addEventListener('click', () => {
            const pageId = item.getAttribute('data-page');
            navItems.forEach(n => n.classList.remove('active'));
            item.classList.add('active');
            sections.forEach(s => {
                s.classList.remove('active');
                if (s.id === pageId) s.classList.add('active');
            });

            // Initialize page-specific data
            if (pageId === 'users') window.fetchUsers();
            if (pageId === 'products') window.fetchProducts();
            if (pageId === 'advice') window.fetchAdvice();
            if (pageId === 'deliveries') window.fetchDeliveries();
            if (pageId === 'communications') window.fetchCommHistory();
        });
    });

    // ── UID Target Field Toggle
    const commTarget = document.getElementById('commTarget');
    commTarget?.addEventListener('change', (e) => {
        const field = document.getElementById('uidTargetField');
        if (field) field.style.display = e.target.value === 'individual' ? 'block' : 'none';
    });

    // ── Product Form Submission
    document.getElementById('productForm')?.addEventListener('submit', handleProductSubmit);

    // ── Global Search
    document.getElementById('globalSearch')?.addEventListener('keypress', e => {
        if (e.key === 'Enter') handleGlobalSearch(e.target.value);
    });

    // ── Init Dashboard
    bootstrapDashboard();
});

// ─────────────────────────────────────────────────────────
//  DASHBOARD TELEMETRY
// ─────────────────────────────────────────────────────────
function bootstrapDashboard() {
    db.collection('Usersstore').onSnapshot(snap => {
        const total = snap.size;
        const farmers = snap.docs.filter(d => d.data().userType === 'farmer').length;
        const vendors = snap.docs.filter(d => d.data().userType === 'vendor').length;
        const drivers = snap.docs.filter(d => d.data().userType === 'driver').length;
        document.getElementById('statTotalUsers').innerText = total;
        if (window._distChart) {
            window._distChart.data.datasets[0].data = [farmers, vendors, drivers];
            window._distChart.update();
        }
    });

    db.collection('agricultural_items').onSnapshot(snap => {
        document.getElementById('statTotalProducts').innerText = snap.size;
    });

    db.collection('delivery_locations').onSnapshot(snap => {
        const online = snap.docs.filter(d => d.data().isOnline).length;
        document.getElementById('statTotalDeliveries').innerText = `${online} / ${snap.size}`;
    });

    db.collection('broadcast_history').onSnapshot(snap => {
        document.getElementById('statTotalNotifs').innerText = snap.size;
    });

    initCharts();
}

// ─────────────────────────────────────────────────────────
//  USER REGISTRY
// ─────────────────────────────────────────────────────────
window.fetchUsers = function () {
    const tbody = document.getElementById('userTableBody');
    if (!tbody) return;
    tbody.innerHTML = '<tr><td colspan="5" class="loader">Querying Node Clusters...</td></tr>';

    if (listeners.users) listeners.users();
    listeners.users = db.collection('Usersstore').orderBy('createdAt', 'desc').onSnapshot(snap => {
        currentUsers = snap.docs.map(d => ({ id: d.id, ...d.data() }));
        tbody.innerHTML = '';
        currentUsers.forEach(u => {
            const role = u.userType || 'Visitor';
            const v = u.profileCompleted ? '<i class="fas fa-check-circle" style="color:#4ADE80"></i> Elite' : '<i class="fas fa-clock" style="color:#FBBF24"></i> Pending';
            const log = u.lastseen ? u.lastseen.toDate().toLocaleTimeString() : 'N/A';

            tbody.innerHTML += `
                <tr>
                    <td><div class="user-cell"><div class="avatar" style="background:#4ADE80">${u.fullName ? u.fullName[0] : 'U'}</div><div><strong>${u.fullName || 'Unknown'}</strong><br><small>${u.id.substring(0, 8)}</small></div></div></td>
                    <td><span class="role-badge ${role.toLowerCase()}">${role}</span></td>
                    <td>${v}</td>
                    <td>${log}</td>
                    <td class="control-cell">
                        <button class="action-btn-sm" onclick="inspectActor('${u.id}')"><i class="fas fa-fingerprint"></i></button>
                        <button class="action-btn-sm" style="color:#EF4444" onclick="deleteDoc('Usersstore','${u.id}')"><i class="fas fa-power-off"></i></button>
                    </td>
                </tr>`;
        });
    });
};

window.inspectActor = (uid) => {
    const user = currentUsers.find(u => u.id === uid);
    if (!user) return;
    const detail = document.getElementById('userDetail');
    const jsonEl = document.getElementById('rawJsonView');
    detail.innerHTML = `
        <p><b>Name:</b> ${user.fullName}</p>
        <p><b>Role:</b> ${user.userType}</p>
        <p><b>Email:</b> ${user.email}</p>
        <p><b>Phone:</b> ${user.phoneNumber}</p>
        <p><b>Location:</b> ${user.farmLocation || user.businessAddress || 'N/A'}</p>
        <p><b>Rating:</b> ⭐ ${user.rating || 0}</p>
    `;
    jsonEl.innerText = JSON.stringify(user, null, 4);
    document.getElementById('userModal').style.display = 'flex';
};

// ─────────────────────────────────────────────────────────
//  PRODUCT MANAGEMENT
// ─────────────────────────────────────────────────────────
window.fetchProducts = function () {
    const grid = document.getElementById('productGrid');
    if (!grid) return;
    grid.innerHTML = '<div class="loader-full">Synchronizing Item Cluster...</div>';

    if (listeners.products) listeners.products();
    listeners.products = db.collection('agricultural_items').onSnapshot(snap => {
        currentProducts = snap.docs.map(d => ({ id: d.id, ...d.data() }));
        grid.innerHTML = '';
        currentProducts.forEach(p => {
            const img = p.imageUrls ? p.imageUrls[0] : 'https://ui-avatars.com/api/?name=' + p.name;
            grid.innerHTML += `
                <div class="product-card">
                    <div class="product-img" style="background-image: url('${img}')"></div>
                    <div class="product-info">
                        <h4>${p.name}</h4>
                        <p>${p.description ? p.description.substring(0, 60) + '...' : 'No description.'}</p>
                        <span class="product-price">${p.price} ETB / ${p.unit}</span>
                        <div style="margin-top:15px; display:flex; gap:10px">
                            <button class="btn-primary" style="flex:1" onclick="openProductModal('${p.id}')">Edit</button>
                            <button class="btn-danger" onclick="deleteDoc('agricultural_items','${p.id}')"><i class="fas fa-trash"></i></button>
                        </div>
                    </div>
                </div>`;
        });
    });
};

window.openProductModal = (id = null) => {
    const modal = document.getElementById('productModal');
    const form = document.getElementById('productForm');
    form.reset();
    document.getElementById('editProductId').value = id || '';
    if (id) {
        const prod = currentProducts.find(p => p.id === id);
        if (prod) {
            document.getElementById('prodName').value = prod.name;
            document.getElementById('prodPrice').value = prod.price;
            document.getElementById('prodUnit').value = prod.unit;
            document.getElementById('prodDesc').value = prod.description;
            document.getElementById('prodCategory').value = prod.category;
        }
    }
    modal.style.display = 'flex';
};

async function handleProductSubmit(e) {
    e.preventDefault();
    const id = document.getElementById('editProductId').value;
    const data = {
        name: document.getElementById('prodName').value,
        price: parseFloat(document.getElementById('prodPrice').value),
        unit: document.getElementById('prodUnit').value,
        description: document.getElementById('prodDesc').value,
        category: document.getElementById('prodCategory').value,
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    };

    try {
        if (id) {
            await db.collection('agricultural_items').doc(id).update(data);
        } else {
            data.createdAt = firebase.firestore.FieldValue.serverTimestamp();
            await db.collection('agricultural_items').add(data);
        }
        closeProductModal();
    } catch (err) { alert("Save Failed: " + err.message); }
}

window.closeProductModal = () => document.getElementById('productModal').style.display = 'none';

// ─────────────────────────────────────────────────────────
//  SMART COMMUNICATIONS
// ─────────────────────────────────────────────────────────
window.sendSmartBroadcast = async function () {
    const target = document.getElementById('commTarget').value;
    const title = document.getElementById('commTitle').value;
    const body = document.getElementById('commBody').value;
    const targetUid = document.getElementById('targetUidInput').value;

    if (!title || !body) return alert("Intel Required: Body & Title.");

    try {
        const btn = document.querySelector('#communications .btn-primary.large');
        btn.disabled = true;
        btn.innerText = "Transmitting...";

        let recipients = [];
        if (target === 'individual') {
            if (!targetUid) throw new Error("Individual target requires UID.");
            recipients = [targetUid];
        } else if (target === 'all') {
            const snap = await db.collection('Usersstore').get();
            recipients = snap.docs.map(d => d.id);
        } else {
            const snap = await db.collection('Usersstore').where('userType', '==', target).get();
            recipients = snap.docs.map(d => d.id);
        }

        const batch = db.batch();
        recipients.forEach(uid => {
            const ref = db.collection('Usersstore').doc(uid).collection('notifications').doc();
            batch.set(ref, {
                title: title,
                message: body,
                timestamp: firebase.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                type: 'broadcast'
            });
        });

        // Log history
        const logRef = db.collection('broadcast_history').doc();
        batch.set(logRef, {
            title, body, target, targetUid: target === 'individual' ? targetUid : null,
            timestamp: firebase.firestore.FieldValue.serverTimestamp(),
            count: recipients.length
        });

        await batch.commit();
        alert(`🛰️ Signal Pushed to ${recipients.length} nodes.`);
        document.getElementById('commTitle').value = '';
        document.getElementById('commBody').value = '';
    } catch (err) { alert("Comm Fail: " + err.message); }
    finally {
        const btn = document.querySelector('#communications .btn-primary.large');
        btn.disabled = false;
        btn.innerText = "Launch Signal";
    }
};

window.fetchCommHistory = () => {
    const list = document.getElementById('commHistory');
    db.collection('broadcast_history').orderBy('timestamp', 'desc').onSnapshot(snap => {
        list.innerHTML = '';
        snap.forEach(doc => {
            const h = doc.data();
            const time = h.timestamp ? h.timestamp.toDate().toLocaleString() : 'Just now';
            list.innerHTML += `
                <div class="log-item">
                    <strong>${h.title}</strong><br>
                    <small>To: ${h.target.toUpperCase()} | Sent: ${time} | Reach: ${h.count}</small>
                </div>`;
        });
    });
};

// ─────────────────────────────────────────────────────────
//  PDF REPORT GENERATION
// ─────────────────────────────────────────────────────────
window.generateDailyPDF = function () {
    const { jsPDF } = window.jspdf;
    const doc = new jsPDF();
    const dateStr = new Date().toLocaleDateString();

    doc.setFontSize(22);
    doc.text("LinkedFarm Operational Intel Report", 20, 20);
    doc.setFontSize(12);
    doc.text(`Generated: ${dateStr}`, 20, 30);

    // Summary Table
    const summaryData = [
        ["Total Actors", currentUsers.length],
        ["Total Inventory", currentProducts.length],
        ["Active Deliveries", document.getElementById('statTotalDeliveries').innerText]
    ];
    doc.autoTable({
        startY: 40,
        head: [['Metric', 'Value']],
        body: summaryData,
        theme: 'striped'
    });

    // Sector Breakdowns
    doc.text("Sector Breakdown (Top 5 Active)", 20, doc.autoTable.previous.finalY + 15);
    const actorData = currentUsers.slice(0, 5).map(u => [u.fullName, u.userType, u.email]);
    doc.autoTable({
        startY: doc.autoTable.previous.finalY + 20,
        head: [['Name', 'Type', 'Email']],
        body: actorData
    });
    doc.text("LINKEDFARM HQ INTEL", 20, 25);
    doc.setFontSize(10);
    doc.text(`SECURITY LEVEL: COMMANDER | ${dateStr}`, 20, 33);

    doc.setTextColor(0, 0, 0);
    doc.setFontSize(14);
    doc.text("1. SECTOR METRICS", 20, 55);

    const farmers = currentUsers.filter(u => u.userType === 'farmer').length;
    const vendors = currentUsers.filter(u => u.userType === 'vendor').length;
    const drivers = currentUsers.filter(u => u.userType === 'driver').length;

    doc.autoTable({
        startY: 60,
        head: [['Sector', 'Active Nodes', 'Status']],
        body: [
            ['Farmers Registry', farmers, 'Normal Operating'],
            ['Vendor Network', vendors, 'High Activity'],
            ['Logistics Partners', drivers, 'Stable'],
            ['Market Inventory', currentProducts.length, 'Aggregating']
        ],
        headStyles: { fillColor: [46, 125, 50] }
    });

    doc.save(`LF_HQ_INTEL_${new Date().toISOString().split('T')[0]}.pdf`);
    alert("🛰️ Intel Report Generated.");
};

// ─────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────
window.deleteDoc = async (col, id) => {
    if (!confirm("Confirm High-Level Purge of document: " + id)) return;
    try { await db.collection(col).doc(id).delete(); } catch (e) { alert("Access Revoked: " + e.message); }
};

window.closeModal = () => {
    document.querySelectorAll('.modal').forEach(m => m.style.display = 'none');
};

function initCharts() {
    const perf = document.getElementById('performanceChart')?.getContext('2d');
    if (perf) {
        new Chart(perf, {
            type: 'line',
            data: {
                labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
                datasets: [{
                    label: 'Market Volume',
                    data: [12, 19, 3, 5, 2, 3, 9],
                    borderColor: '#4ADE80',
                    tension: 0.4
                }]
            },
            options: { responsive: true, plugins: { legend: { display: false } } }
        });
    }

    const dist = document.getElementById('distributionChart')?.getContext('2d');
    if (dist) {
        window._distChart = new Chart(dist, {
            type: 'doughnut',
            data: {
                labels: ['Farmers', 'Vendors', 'Drivers'],
                datasets: [{
                    data: [10, 10, 10],
                    backgroundColor: ['#4ADE80', '#FBBF24', '#60A5FA']
                }]
            },
            options: { responsive: true, cutout: '80%' }
        });
    }
}
