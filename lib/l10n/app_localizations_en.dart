// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LinkedFarm';

  @override
  String get home => 'Home';

  @override
  String get sellProduce => 'Sell Produce';

  @override
  String get myProducts => 'My Products';

  @override
  String get marketPrices => 'Market Prices';

  @override
  String stockLevel(int count, String unit) {
    return 'Stock Level: $count $unit';
  }

  @override
  String get outOfStock => 'Out of Stock';

  @override
  String get lowStock => 'Low Stock!';

  @override
  String get updateStock => 'Update Stock';

  @override
  String get quantityUpdated => 'Quantity updated successfully';

  @override
  String get stock => 'Stock';

  @override
  String get messages => 'Messages';

  @override
  String get deliveryServices => 'Delivery Services';

  @override
  String get expertAdvice => 'Expert Advice';

  @override
  String get landPlanner => 'My Land Planner';

  @override
  String get welcomeBack => 'Welcome back!';

  @override
  String get manageFarm => 'Manage your farm and crops efficiently.';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get farmerDashboard => 'Farmer Dashboard';

  @override
  String get loginSubTitle => 'Login to your account';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get loginButton => 'Login';

  @override
  String get noAccount => 'Don\'t have an account? ';

  @override
  String get registerAction => 'Register';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get fillAllFields => 'Please fill all fields';

  @override
  String get userNotFound => 'User not found';

  @override
  String get wrongPassword => 'Wrong password';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get userDisabled => 'User disabled';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get completeProfileSetup => 'Please complete your profile setup.';

  @override
  String get completeProfile => 'Please complete your profile.';

  @override
  String get registerSubTitle => 'Create your account';

  @override
  String get fullNameHint => 'Enter your full name';

  @override
  String get phoneHint => 'Enter your phone number';

  @override
  String get selectRole => 'Select your role';

  @override
  String get roleFarmer => 'Farmer';

  @override
  String get roleVendor => 'Vendor';

  @override
  String get roleAdvisor => 'Expert Advisor';

  @override
  String get roleDelivery => 'Delivery';

  @override
  String get roleShopper => 'Shopper (Input Supplier)';

  @override
  String get confirmPasswordHint => 'Confirm your password';

  @override
  String get registerButton => 'Register';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get passwordsNotMatch => 'Passwords do not match';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get registrationSuccess => 'Registration successful!';

  @override
  String get emailInUse => 'Email already in use';

  @override
  String get weakPassword => 'Password is too weak';

  @override
  String get invalidEmailAddress => 'Invalid email address';

  @override
  String get completeProfileTitle => 'Complete Your Profile';

  @override
  String get userNotLoggedIn => 'User not logged in';

  @override
  String get userDataNotFound => 'User data not found';

  @override
  String get profileCompletedSuccess => 'Profile completed successfully!';

  @override
  String get profileCompletedFailed => 'Failed to complete profile';

  @override
  String get deliveryInfoTitle => 'Delivery Information';

  @override
  String get yourLocationLabel => 'Your location';

  @override
  String get carTypeLabel => 'Car Type';

  @override
  String get licenseIdLabel => 'Driven license id';

  @override
  String get reviewCompleteTitle => 'Review & Complete';

  @override
  String get reviewInfoLabel => 'Review your information:';

  @override
  String get locationLabel => 'Location:';

  @override
  String get licenseIdPrefix => 'License ID:';

  @override
  String get carTypePrefix => 'Car Type:';

  @override
  String get clickCompleteLabel =>
      'Click Complete to finish your profile setup.';

  @override
  String get farmInfoTitle => 'Farm Information';

  @override
  String get farmNameLabel => 'Farm Name';

  @override
  String get farmLocationLabel => 'Farm Location';

  @override
  String get farmSizeLabel => 'Farm Size (acres)';

  @override
  String get cropsGrownLabel => 'Crops Grown';

  @override
  String get cropsHint => 'e.g., Coffee, Maize, Vegetables';

  @override
  String get businessInfoTitle => 'Business Information';

  @override
  String get businessNameLabel => 'Business Name';

  @override
  String get businessTypeLabel => 'Business Type';

  @override
  String get businessTypeHint => 'e.g., Supplier, Retailer, Wholesaler';

  @override
  String get contactPersonLabel => 'Contact Person';

  @override
  String get businessAddressLabel => 'Business Address';

  @override
  String get productsServicesLabel => 'Products/Services';

  @override
  String get productsServicesHint => 'e.g., Fertilizers, Seeds, Equipment';

  @override
  String get professionalProfileTitle => 'Professional Profile';

  @override
  String get specializationLabel => 'Specialization';

  @override
  String get specializationHint => 'e.g., Crop Science, Animal Health';

  @override
  String get experienceLabel => 'Experience (Years)';

  @override
  String get qualificationLabel => 'Qualification / Degree';

  @override
  String get farmerProfileSetup => 'Farmer Profile Setup';

  @override
  String get vendorProfileSetup => 'Vendor Profile Setup';

  @override
  String get advisorProfileSetup => 'Expert Advisor Profile Setup';

  @override
  String get shopperProfileSetup => 'Shopper Profile Setup';

  @override
  String get defaultProfileSetup => 'Profile Setup';

  @override
  String welcomeName(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get resetLinkSent => 'Reset link sent! Check your inbox.';

  @override
  String get noAccountFound => 'No account found with this email.';

  @override
  String get invalidEmailFormat => 'Invalid email format.';

  @override
  String get networkError =>
      'Network error. Please check your internet connection.';

  @override
  String get passwordRecoveryTitle => 'Password Recovery';

  @override
  String get enterRegisteredEmail => 'Enter your registered email';

  @override
  String get emailAddressLabel => 'Email address';

  @override
  String get sendResetLinkButton => 'Send Reset Link';

  @override
  String get signUpAction => 'Sign up';

  @override
  String comingSoon(String feature) {
    return '$feature coming soon!';
  }

  @override
  String get productImagesTitle => 'Product Images';

  @override
  String get addPhotosTitle => 'Add Photos';

  @override
  String get chooseImageSource => 'Choose image source';

  @override
  String get cameraAction => 'Camera';

  @override
  String get galleryAction => 'Gallery';

  @override
  String get photoAddedSuccess => 'Photo added successfully';

  @override
  String get errorTakingPhoto => 'Error taking photo';

  @override
  String get errorSelectingImages => 'Error selecting images';

  @override
  String get photoRemoved => 'Photo removed';

  @override
  String get locationSelectedSuccess => 'Location selected successfully';

  @override
  String get enterProductName => 'Please enter product name';

  @override
  String get selectCategory => 'Please select a category';

  @override
  String get enterProductDescription => 'Please enter product description';

  @override
  String get enterValidPrice => 'Please enter a valid price';

  @override
  String get enterValidQuantity => 'Please enter a valid quantity';

  @override
  String get selectLocation => 'Please select a location';

  @override
  String get enterSellerName => 'Please enter seller name';

  @override
  String get enterContactInfo => 'Please enter contact information';

  @override
  String get addAtLeastOnePhoto => 'Please add at least one product photo';

  @override
  String get uploading => 'Uploading...';

  @override
  String uploadingImagesCount(int count) {
    return 'Uploading $count new image(s)';
  }

  @override
  String get takeAMoment => 'This may take a few moments';

  @override
  String get savedLocallySyncLater =>
      'Saved locally! Will sync when internet is back.';

  @override
  String get errorTitle => 'Error';

  @override
  String get okAction => 'OK';

  @override
  String get retryAction => 'Retry';

  @override
  String get successTitle => 'Success!';

  @override
  String itemListedSuccess(String name) {
    return '$name has been listed successfully!';
  }

  @override
  String imagesUploadedCloudinary(int count) {
    return '$count image(s) uploaded to Cloudinary';
  }

  @override
  String get itemLiveMarketplace => 'Your item is now live on the marketplace.';

  @override
  String get addAnotherAction => 'Add Another';

  @override
  String get doneAction => 'Done';

  @override
  String get formCleared => 'Form cleared';

  @override
  String get productInformation => 'Product Information';

  @override
  String get productNameLabel => 'Product Name *';

  @override
  String get categoryLabel => 'Category *';

  @override
  String get subcategoryOptional => 'Subcategory (Optional)';

  @override
  String get descriptionLabel => 'Description *';

  @override
  String get describeProductDetail => 'Describe your product in detail...';

  @override
  String get priceEtbLabel => 'Price (ETB) *';

  @override
  String get quantityLabel => 'Quantity *';

  @override
  String get unitLabel => 'Unit';

  @override
  String get conditionLabel => 'Condition';

  @override
  String get locationTitle => 'Location';

  @override
  String get locationOnMap => 'Location on Map *';

  @override
  String get tapToSelectLocation => 'Tap to select location';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get sellProduceAction => 'Sell Produce';

  @override
  String addMorePhotos(int count) {
    return 'Add More Photos ($count/10)';
  }

  @override
  String get deleteProductTitle => 'Delete Product';

  @override
  String deleteProductConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get cancelAction => 'Cancel';

  @override
  String get deleteAction => 'Delete';

  @override
  String get productDeletedSuccess => 'Product deleted successfully';

  @override
  String get loginToViewProducts => 'Please login to view your products';

  @override
  String get myProductsTitle => 'My Products';

  @override
  String get noProductsListed => 'You haven\'t listed any products yet';

  @override
  String get listFirstProductButton => 'List Your First Product';

  @override
  String get editAction => 'Edit';

  @override
  String get shareNearbyAction => 'Share with Nearby';

  @override
  String viewsLabel(int count) {
    return '$count Views';
  }

  @override
  String likesLabel(int count) {
    return '$count Likes';
  }

  @override
  String get shareWifiTitle => 'Share via Wi-Fi';

  @override
  String get enterFarmerIpLabel => 'Enter the nearby farmer\'s IP address:';

  @override
  String propagatingToIp(String ip) {
    return 'Propagating to $ip...';
  }

  @override
  String get propagatedSuccess => 'Propagated successfully!';

  @override
  String failedToConnectIp(String ip) {
    return 'Failed to connect to $ip';
  }

  @override
  String get sendAction => 'Send';

  @override
  String get catCereals => 'Cereals';

  @override
  String get catPulses => 'Pulses';

  @override
  String get catVegetables => 'Vegetables';

  @override
  String get catFruits => 'Fruits';

  @override
  String get catSpices => 'Spices';

  @override
  String get catCoffee => 'Coffee';

  @override
  String get catOilSeeds => 'Oil Seeds';

  @override
  String get catTubers => 'Tubers';

  @override
  String get catLivestock => 'Livestock';

  @override
  String get catOthers => 'Others';

  @override
  String get condFresh => 'Fresh';

  @override
  String get condDry => 'Dry';

  @override
  String get condOrganic => 'Organic';

  @override
  String get condProcessed => 'Processed';

  @override
  String get condFrozen => 'Frozen';

  @override
  String get unitKg => 'kg';

  @override
  String get unitQuintal => 'quintal';

  @override
  String get unitTon => 'ton';

  @override
  String get unitSack => 'sack';

  @override
  String get unitPiece => 'piece';

  @override
  String get unitLiter => 'liter';

  @override
  String get addClearPhotosHint =>
      'Add clear photos of your product from different angles';

  @override
  String get locationNotFound => 'Location not found';

  @override
  String get unableToFindLocation =>
      'Unable to find location. Please try again.';

  @override
  String get searchLocationHint => 'Search location...';

  @override
  String get selectLocationTitle => 'Select Location';

  @override
  String get draggingStatus => 'Dragging...';

  @override
  String get fetchingStatus => 'Fetching...';

  @override
  String get confirmLocationButton => 'Confirm Location';

  @override
  String get unknownLocation => 'Unknown Location';

  @override
  String get catPesticide => 'Pesticide';

  @override
  String get catHerbicide => 'Herbicide';

  @override
  String get catFungicide => 'Fungicide';

  @override
  String get catFertilizer => 'Fertilizer';

  @override
  String get buyInputs => 'Buy Agricultural Inputs';

  @override
  String get sellInputs => 'Sell Agricultural Inputs';

  @override
  String get offline => 'Offline';

  @override
  String get synced => 'Synced';

  @override
  String get readMore => 'Read More';

  @override
  String get noAdvice => 'No advice posts yet.';

  @override
  String get expertAdviceTitle => 'Expert Advice & Tips';

  @override
  String get playVoiceGuide => 'Play Voice Guide';

  @override
  String get stopVoiceGuide => 'Stop Voice Guide';

  @override
  String byAuthor(Object name) {
    return 'By $name';
  }

  @override
  String get smartAdvisory => 'Smart Advisory';

  @override
  String get aiAgronomist => 'AI AGRONOMIST';

  @override
  String get expertPanel => 'EXPERT PANEL';

  @override
  String get cropHealthAnalysis => 'Crop Health Analysis';

  @override
  String get excellentCondition => 'EXCELLENT CONDITION';

  @override
  String get attentionNeeded => 'ATTENTION NEEDED';

  @override
  String cropHealthSummary(Object crop, Object status) {
    return 'Based on your latest photo and sensor readings, your $crop is developing $status.';
  }

  @override
  String get optimally => 'optimally';

  @override
  String get slowerThanExpected => 'slower than expected';

  @override
  String get aiRecommendations => 'AI Recommendations';

  @override
  String get irrigation => 'Irrigation';

  @override
  String moistureLow(Object percent) {
    return 'Soil moisture is critically low ($percent%). Initiate irrigation immediately to prevent wilting.';
  }

  @override
  String get moistureOptimal =>
      'Moisture levels are optimal. No irrigation needed today.';

  @override
  String get nutrients => 'Nutrients';

  @override
  String get nutrientsLow =>
      'NPK levels are depleting. Apply organic compost or NPK 15-15-15 within the next 2 days.';

  @override
  String get nutrientsStable =>
      'Nutrient balance is stable. Continue monitoring.';

  @override
  String get pestDisease => 'Pest & Disease';

  @override
  String get pestHighRisk =>
      'High humidity detected. Risk of fungal infection is elevated. Inspect leaves for spots.';

  @override
  String get pestLowRisk =>
      'Low pest risk detected. Maintaining field hygiene is recommended.';

  @override
  String get urgent => 'URGENT';

  @override
  String get connectWithExperts => 'Connect with Experts';

  @override
  String get getProfessionalGuidance =>
      'Get professional guidance for your farm.';

  @override
  String get requestConsultation => 'Request Consultation';

  @override
  String get online => 'Online';

  @override
  String get away => 'Away';

  @override
  String get crop => 'crop';

  @override
  String get predictedRain => 'PREDICTED: 8mm RAIN';

  @override
  String get clearSkies => 'CLEAR SKIES';

  @override
  String get pest => 'PEST';

  @override
  String get fungal => 'FUNGAL';

  @override
  String get weeds => 'WEEDS';

  @override
  String get soilMoistureProfile => 'SOIL MOISTURE PROFILE';

  @override
  String dayLabel(Object day) {
    return 'DAY $day';
  }

  @override
  String get vegetativeCycle => 'VEGETATIVE CYCLE';

  @override
  String get myCustomLandPlan => 'MY CUSTOM LAND PLAN';

  @override
  String get plannerDetail =>
      'Enter and track your daily/weekly farming tasks.';

  @override
  String get dailyLogBtn => 'DAILY\nLOG';

  @override
  String get plannerBtn => 'PLANNER';

  @override
  String get advisorBtn => 'ADVISOR';

  @override
  String get fertilizeBtn => 'FERTILIZE';

  @override
  String get proceedNextDay => 'PROCEED TO NEXT DAY';

  @override
  String get tapDeepAnalysis => 'Tap for Deep AI Analysis';

  @override
  String get aiDeepAnalysisTitle => 'AI DEEP ANALYSIS';

  @override
  String get gotIt => 'GOT IT';

  @override
  String get emptyPlanner => 'Your Custom Plan is Empty';

  @override
  String get emptyPlannerDetail => 'Add your own daily/weekly tasks here.';

  @override
  String get entryManualPlanTitle => 'ENTRY FOR MANUAL PLAN';

  @override
  String get cancel => 'CANCEL';

  @override
  String get savePlan => 'SAVE PLAN';

  @override
  String get taskTitle => 'Task Title';

  @override
  String get activityDetail => 'Activity Detail';

  @override
  String get daily => 'DAILY';

  @override
  String get weekly => 'WEEKLY';

  @override
  String get monthly => 'MONTHLY';

  @override
  String get completed => 'COMPLETED';

  @override
  String get advicePest =>
      'Pest activity is increasing due to temperature and wind conditions.';

  @override
  String get adviceMoistureLow =>
      'Moisture levels are low. Hope for rain in the forecast soon!';

  @override
  String get adviceRainy =>
      'Natural rainfall is replenishing the soil moisture profile.';

  @override
  String get adviceStable =>
      'Ecosystem is stable. Rain-dependent growth is within parameters.';

  @override
  String get virtualFarmSimulator => 'Virtual Farm Simulator';

  @override
  String get welcomeVirtualFarm => 'Welcome to Your Virtual Farm';

  @override
  String get gameIntro =>
      'Learn farming by doing. Make decisions, manage resources, and see how AI predicts your harvest!';

  @override
  String get startNewFarm => 'Start New Farm';

  @override
  String continueFarming(Object day) {
    return 'Continue Farming (Day $day)';
  }

  @override
  String get resetStartNew => 'Reset and Start New';

  @override
  String get myLandsProfile => 'MY LANDS PROFILE';

  @override
  String get noLandsRegistered => 'No lands registered yet.';

  @override
  String get startAddingPlot => 'Start by adding your first plot of land.';

  @override
  String get registerNewLand => 'REGISTER NEW LAND';

  @override
  String get landNameHint => 'Land Name (e.g. Home Garden)';

  @override
  String get sizeHectares => 'Size (Hectares)';

  @override
  String get soilType => 'Soil Type';

  @override
  String get saveLand => 'SAVE LAND';

  @override
  String get hectares => 'Hectares';

  @override
  String get readyPlanting => 'READY FOR PLANTING';

  @override
  String get cycleCompleted => 'CYCLE COMPLETED';

  @override
  String dayTrackerTitle(Object day) {
    return 'Day $day Tracker';
  }

  @override
  String get sensorDataCollection => 'Sensor-Based Data Collection';

  @override
  String get connectCableDetail =>
      'Connect cable to read soil & environmental data';

  @override
  String get soilSensorCable => 'Soil Sensor Cable';

  @override
  String get statusConnected => 'Status: Connected';

  @override
  String get statusDisconnected => 'Status: Disconnected';

  @override
  String get connect => 'CONNECT';

  @override
  String get observations => 'Observations';

  @override
  String get enterNotes => 'Enter your notes here...';

  @override
  String get saveDailyLog => 'SAVE DAILY LOG';

  @override
  String sensorConnectedMsg(Object type) {
    return '✅ Sensor Connected! Detected: $type soil';
  }

  @override
  String get dailyLogSavedMsg => '✅ Daily log saved to Firestore!';

  @override
  String get moisture => 'Moisture';

  @override
  String get temp => 'Temp';

  @override
  String get nitrogen => 'Nitrogen';

  @override
  String get phosphorus => 'Phosphorus';

  @override
  String get potassium => 'Potassium';

  @override
  String get loamy => 'Loamy';

  @override
  String get silt => 'Silt';

  @override
  String get clay => 'Clay';

  @override
  String get sandy => 'Sandy';

  @override
  String get welcomeToAgrilead => 'Welcome to LinkedFarm.';

  @override
  String get tapLoginReady => 'Tap the Login button when ready.';

  @override
  String get productInventoryIntro => 'This is your product inventory.';

  @override
  String get startSellingIntro =>
      'Tap \'List Your First Product\' or the + button to start selling.';

  @override
  String get registerFieldsIntro => 'Complete these fields to register.';

  @override
  String get registerFinishIntro => 'Tap Register when finished.';

  @override
  String get dailyTrackerIntro => 'Check today\'s farming tasks here.';

  @override
  String get farmMainIntro => 'See how your farm is progressing.';

  @override
  String get gameDashboardIntro => 'Get AI advice for your crops.';

  @override
  String get sellItemIntro =>
      'Describe your item, set a price, and add photos to start selling.';

  @override
  String get growthJournalIntro => 'Review your farm\'s history here.';

  @override
  String get growthJournalDetail =>
      'Each card shows your soil and health status for that day.';

  @override
  String get seasonalReportIntro => 'This is your seasonal success report.';

  @override
  String get seasonalReportDetail =>
      'Review your activity completion rate and estimated yield success.';

  @override
  String get productListIntro =>
      'Browse seeds, fertilizers, and tools available for purchase.';

  @override
  String get productListSearchInfo =>
      'Use the search bar or category chips to find specific items.';

  @override
  String get productListContactInfo =>
      'Tap on an item to see details or contact the seller.';

  @override
  String get marketPricesIntro =>
      'Check the latest market prices for your crops here.';

  @override
  String get marketPricesGuidance =>
      'Compare minimum and maximum prices to decide the best time to sell.';

  @override
  String get adviceFeedIntro =>
      'Browse the latest tips and advice from agricultural experts.';

  @override
  String get tabLearn => 'Learn';

  @override
  String get tabAiPro => 'AI Agronomist';

  @override
  String get tabPulse => 'Farming Pulse';

  @override
  String get learnHeroTitle => 'Confidence in Farming';

  @override
  String get learnHeroSub =>
      'Modern tools, science, and business skills for the modern farmer.';

  @override
  String get freeCourses => 'Free Courses';

  @override
  String get premiumLearning => 'Premium Learning';

  @override
  String get predictiveAiTitle => 'Predictive Farming AI';

  @override
  String get expectedYield => 'Expected Yield Prediction:';

  @override
  String get yieldHigh => 'High';

  @override
  String get yieldAvg => 'Average to High';

  @override
  String get yieldLow => 'Low';

  @override
  String get weatherOutlook => '5-Day Weather Outlook';

  @override
  String get soilVitality => 'Soil Vitality';

  @override
  String get pHLevel => 'pH Level';

  @override
  String get aiAnalysisResult => 'AI Recommendations';

  @override
  String get aiDiagnosisIntro =>
      'Your analysis results will appear here. AI can recommend pesticides, herbicides, and fungicides.';

  @override
  String get visionAnalysisInfo =>
      'Our AI uses multi-modal vision to identify infections on crops and recommend precise treatments.';
}
