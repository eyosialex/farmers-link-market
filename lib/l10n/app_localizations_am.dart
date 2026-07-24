// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appTitle => 'አግሪሊድ';

  @override
  String get home => 'መነሻ';

  @override
  String get sellProduce => 'ምርት ይሽጡ';

  @override
  String get myProducts => 'የእኔ ምርቶች';

  @override
  String get marketPrices => 'የገበያ ዋጋ';

  @override
  String stockLevel(int count, String unit) {
    return 'ክምችት መጠን፡ $count $unit';
  }

  @override
  String get outOfStock => 'ያለቀ';

  @override
  String get lowStock => 'አነስተኛ ክምችት!';

  @override
  String get updateStock => 'ክምችት አዘምን';

  @override
  String get quantityUpdated => 'መጠኑ በትክክል ተዘምኗል';

  @override
  String get stock => 'ክምችት';

  @override
  String get messages => 'መልዕክቶች';

  @override
  String get deliveryServices => 'የማጓጓዣ አገልግሎቶች';

  @override
  String get expertAdvice => 'የባለሙያ ምክር';

  @override
  String get landPlanner => 'የመሬት እቅድ አውጪ';

  @override
  String get welcomeBack => 'እንኳን ደህና መጡ!';

  @override
  String get manageFarm => 'እርሻዎን እና ሰብሎችዎን በብቃት ያስተዳድሩ።';

  @override
  String get selectLanguage => 'ቋንቋ ይምረጡ';

  @override
  String get farmerDashboard => 'የአርሶ አደር ዳሽቦርድ';

  @override
  String get loginSubTitle => 'ወደ መለያዎ ይግቡ';

  @override
  String get emailHint => 'ኢሜልዎን ያስገቡ';

  @override
  String get passwordHint => 'የይለፍ ቃልዎን ያስገቡ';

  @override
  String get loginButton => 'ግባ';

  @override
  String get noAccount => 'መለያ የለዎትም? ';

  @override
  String get registerAction => 'ይመዝገቡ';

  @override
  String get forgotPassword => 'የይለፍ ቃል ረስተዋል?';

  @override
  String get fillAllFields => 'እባክዎ ሁሉንም መስኮች ይሙሉ';

  @override
  String get userNotFound => 'ተጠቃሚ አልተገኘም';

  @override
  String get wrongPassword => 'የተሳሳተ የይለፍ ቃል';

  @override
  String get invalidEmail => 'የተሳሳተ ኢሜል';

  @override
  String get userDisabled => 'ተጠቃሚው ታግዷል';

  @override
  String get somethingWentWrong => 'ችግር ተፈጥሯል';

  @override
  String get completeProfileSetup => 'እባክዎ የመለያዎን ዝግጅት ያጠናቅቁ።';

  @override
  String get completeProfile => 'እባክዎ መገለጫዎን ያጠናቅቁ።';

  @override
  String get registerSubTitle => 'መለያዎን ይፍጠሩ';

  @override
  String get fullNameHint => 'ሙሉ ስምዎን ያስገቡ';

  @override
  String get phoneHint => 'የስልክ ቁጥርዎን ያስገቡ';

  @override
  String get selectRole => 'ሚናዎን ይምረጡ';

  @override
  String get roleFarmer => 'አርሶ አደር';

  @override
  String get roleVendor => 'ነጋዴ';

  @override
  String get roleAdvisor => 'አማካሪ ባለሙያ';

  @override
  String get roleDelivery => 'አቅራቢ/መልእክተኛ';

  @override
  String get roleShopper => 'ሾፐር (ግብዓት አቅራቢ)';

  @override
  String get confirmPasswordHint => 'የይለፍ ቃልዎን ያረጋግጡ';

  @override
  String get registerButton => 'ይመዝገቡ';

  @override
  String get alreadyHaveAccount => 'ቀድሞውኑ መለያ አለዎት? ';

  @override
  String get passwordsNotMatch => 'የይለፍ ቃላት አይዛመዱም';

  @override
  String get passwordTooShort => 'የይለፍ ቃል ቢያንስ 6 ቁምፊዎች መሆን አለበት';

  @override
  String get registrationSuccess => 'ምዝገባው በተሳካ ሁኔታ ተጠናቅቋል!';

  @override
  String get emailInUse => 'ኢሜል አስቀድሞ ጥቅም ላይ ውሏል';

  @override
  String get weakPassword => 'የይለፍ ቃሉ በጣም ደካማ ነው';

  @override
  String get invalidEmailAddress => 'የተሳሳተ የኢሜል አድራሻ';

  @override
  String get completeProfileTitle => 'መገለጫዎን ያጠናቅቁ';

  @override
  String get userNotLoggedIn => 'ተጠቃሚ አልገባም';

  @override
  String get userDataNotFound => 'የተጠቃሚ ውሂብ አልተገኘም';

  @override
  String get profileCompletedSuccess => 'መገለጫ በተሳካ ሁኔታ ተጠናቅቋል!';

  @override
  String get profileCompletedFailed => 'መገለጫውን ማጠናቀቅ አልተቻለም';

  @override
  String get deliveryInfoTitle => 'የማድረሻ መረጃ';

  @override
  String get yourLocationLabel => 'የእርስዎ አካባቢ';

  @override
  String get carTypeLabel => 'የመኪና ዓይነት';

  @override
  String get licenseIdLabel => 'የመንጃ ፍቃድ መታወቂያ';

  @override
  String get reviewCompleteTitle => 'ይገምግሙ እና ያጠናቅቁ';

  @override
  String get reviewInfoLabel => 'መረጃዎን ይገምግሙ፡';

  @override
  String get locationLabel => 'አካባቢ፡';

  @override
  String get licenseIdPrefix => 'የፍቃድ መታወቂያ፡';

  @override
  String get carTypePrefix => 'የመኪና ዓይነት፡';

  @override
  String get clickCompleteLabel => 'የመገለጫ ዝግጅትዎን ለማጠናቀቅ አጠናቅቅ የሚለውን ይጫኑ።';

  @override
  String get farmInfoTitle => 'የእርሻ መረጃ';

  @override
  String get farmNameLabel => 'የእርሻ ስም';

  @override
  String get farmLocationLabel => 'የእርሻ ቦታ';

  @override
  String get farmSizeLabel => 'የእርሻ መጠን (በኤከር)';

  @override
  String get cropsGrownLabel => 'የሚመረቱ ሰብሎች';

  @override
  String get cropsHint => 'ለምሳሌ፡ ቡና፣ በቆሎ፣ አትክልት';

  @override
  String get businessInfoTitle => 'የንግድ መረጃ';

  @override
  String get businessNameLabel => 'የንግድ ስም';

  @override
  String get businessTypeLabel => 'የንግድ ዓይነት';

  @override
  String get businessTypeHint => 'ለምሳሌ፡ አቅራቢ፣ ቸርቻሪ፣ ጅምላ ሻጭ';

  @override
  String get contactPersonLabel => 'ተጠሪ ሰው';

  @override
  String get businessAddressLabel => 'የንግድ አድራሻ';

  @override
  String get productsServicesLabel => 'ምርቶች/አገልግሎቶች';

  @override
  String get productsServicesHint => 'ለምሳሌ፡ ማዳበሪያ፣ ዘር፣ መሳሪያዎች';

  @override
  String get professionalProfileTitle => 'የሙያ መገለጫ';

  @override
  String get specializationLabel => 'ልዩ ሙያ';

  @override
  String get specializationHint => 'ለምሳሌ፡ የሰብል ሳይንስ፣ የእንስሳት ጤና';

  @override
  String get experienceLabel => 'ልምድ (በዓመታት)';

  @override
  String get qualificationLabel => 'ደረጃ / ዲግሪ';

  @override
  String get farmerProfileSetup => 'የአርሶ አደር መገለጫ ዝግጅት';

  @override
  String get vendorProfileSetup => 'የነጋዴ መገለጫ ዝግጅት';

  @override
  String get advisorProfileSetup => 'የአማካሪ ባለሙያ መገለጫ ዝግጅት';

  @override
  String get shopperProfileSetup => 'የሾፐር መገለጫ ዝግጅት';

  @override
  String get defaultProfileSetup => 'የመገለጫ ዝግጅት';

  @override
  String welcomeName(String name) {
    return 'እንኳን ደህና መጡ፣ $name!';
  }

  @override
  String get resetLinkSent => 'የይለፍ ቃል መቀየሪያ ሊንክ ተልኳል! ኢሜልዎን ይፈትሹ።';

  @override
  String get noAccountFound => 'በዚህ ኢሜል የተመዘገበ መለያ አልተገኘም።';

  @override
  String get invalidEmailFormat => 'የተሳሳተ የኢሜል ፎርማት።';

  @override
  String get networkError => 'የኔትወርክ ስህተት። እባክዎ ኢንተርኔትዎን ያረጋግጡ።';

  @override
  String get passwordRecoveryTitle => 'የይለፍ ቃል መልሶ ማግኛ';

  @override
  String get enterRegisteredEmail => 'የተመዘገበ ኢሜልዎን ያስገቡ';

  @override
  String get emailAddressLabel => 'የኢሜል አድራሻ';

  @override
  String get sendResetLinkButton => 'ሊንክ ላክ';

  @override
  String get signUpAction => 'ይመዝገቡ';

  @override
  String comingSoon(String feature) {
    return '$feature በቅርቡ ይቀርባል!';
  }

  @override
  String get productImagesTitle => 'የምርት ምስሎች';

  @override
  String get addPhotosTitle => 'ምስሎችን ያክሉ';

  @override
  String get chooseImageSource => 'የምስል ምንጭ ይምረጡ';

  @override
  String get cameraAction => 'ካሜራ';

  @override
  String get galleryAction => 'ጋለሪ';

  @override
  String get photoAddedSuccess => 'ምስል በተሳካ ሁኔታ ተጨምሯል';

  @override
  String get errorTakingPhoto => 'ፎቶ በማንሳት ላይ ስህተት ተከስቷል';

  @override
  String get errorSelectingImages => 'ምስሎችን በመምረጥ ላይ ስህተት ተከስቷል';

  @override
  String get photoRemoved => 'ምስል ተወግዷል';

  @override
  String get locationSelectedSuccess => 'ቦታ በተሳካ ሁኔታ ተመርጧል';

  @override
  String get enterProductName => 'እባክዎ የምርት ስም ያስገቡ';

  @override
  String get selectCategory => 'እባክዎ ምድብ ይምረጡ';

  @override
  String get enterProductDescription => 'እባክዎ የምርት መግለጫ ያስገቡ';

  @override
  String get enterValidPrice => 'እባክዎ ትክክለኛ ዋጋ ያስገቡ';

  @override
  String get enterValidQuantity => 'እባክዎ ትክክለኛ መጠን ያስገቡ';

  @override
  String get selectLocation => 'እባክዎ ቦታ ይምረጡ';

  @override
  String get enterSellerName => 'እባክዎ የሻጭ ስም ያስገቡ';

  @override
  String get enterContactInfo => 'እባክዎ የመገናኛ መረጃ ያስገቡ';

  @override
  String get addAtLeastOnePhoto => 'እባክዎ ቢያንስ አንድ የምርት ፎቶ ያክሉ';

  @override
  String get uploading => 'በመጫን ላይ...';

  @override
  String uploadingImagesCount(int count) {
    return '$count አዲስ ምስሎችን በመጫን ላይ';
  }

  @override
  String get takeAMoment => 'ይህ ጥቂት ጊዜ ሊወስድ ይችላል';

  @override
  String get savedLocallySyncLater => 'በአካባቢው ተቀምጧል! ኢንተርኔት ሲኖር ይላካል።';

  @override
  String get errorTitle => 'ስህተት';

  @override
  String get okAction => 'እሺ';

  @override
  String get retryAction => 'እንደገና ይሞክሩ';

  @override
  String get successTitle => 'ተሳክቷል!';

  @override
  String itemListedSuccess(String name) {
    return '$name በተሳካ ሁኔታ ለገበያ ቀርቧል!';
  }

  @override
  String imagesUploadedCloudinary(int count) {
    return '$count ምስሎች ተጭነዋል';
  }

  @override
  String get itemLiveMarketplace => 'ምርትዎ አሁን በገበያ ላይ ይገኛል።';

  @override
  String get addAnotherAction => 'ሌላ ጨምር';

  @override
  String get doneAction => 'ተጠናቀቀ';

  @override
  String get formCleared => 'ቅጹ ጸድቷል';

  @override
  String get productInformation => 'የምርት መረጃ';

  @override
  String get productNameLabel => 'የምርት ስም *';

  @override
  String get categoryLabel => 'ምድብ *';

  @override
  String get subcategoryOptional => 'ንዑስ ምድብ (አማራጭ)';

  @override
  String get descriptionLabel => 'መግለጫ *';

  @override
  String get describeProductDetail => 'ስለ ምርቱ ዝርዝር መግለጫ ይስጡ...';

  @override
  String get priceEtbLabel => 'ዋጋ (በብር) *';

  @override
  String get quantityLabel => 'መጠን *';

  @override
  String get unitLabel => 'መመዘኛ';

  @override
  String get conditionLabel => 'ሁኔታ';

  @override
  String get locationTitle => 'ቦታ';

  @override
  String get locationOnMap => 'ቦታ በካርታ ላይ *';

  @override
  String get tapToSelectLocation => 'ቦታ ለመምረጥ ይጫኑ';

  @override
  String get editProduct => 'ምርት ይቀይሩ';

  @override
  String get sellProduceAction => 'ምርት ይሽጡ';

  @override
  String addMorePhotos(int count) {
    return 'ተጨማሪ ምስሎችን ያክሉ ($count/10)';
  }

  @override
  String get deleteProductTitle => 'ምርት ይሰርዙ';

  @override
  String deleteProductConfirm(String name) {
    return '\"$name\" መሰረዝዎን እርግጠኛ ነዎት?';
  }

  @override
  String get cancelAction => 'አይሁን';

  @override
  String get deleteAction => 'ሰርዝ';

  @override
  String get productDeletedSuccess => 'ምርት በተሳካ ሁኔታ ተሰርዟል';

  @override
  String get loginToViewProducts => 'ምርቶችዎን ለማየት እባክዎ ይግቡ';

  @override
  String get myProductsTitle => 'የእኔ ምርቶች';

  @override
  String get noProductsListed => 'እስካሁን ምንም ምርት አላቀረቡም';

  @override
  String get listFirstProductButton => 'የመጀመሪያ ምርትዎን ያቅርቡ';

  @override
  String get editAction => 'አስተካክል';

  @override
  String get shareNearbyAction => 'ለአቅራቢያ ያካፍሉ';

  @override
  String viewsLabel(int count) {
    return '$count እይታዎች';
  }

  @override
  String likesLabel(int count) {
    return '$count ተወዳጅነት';
  }

  @override
  String get shareWifiTitle => 'በዋይፋይ ያካፍሉ';

  @override
  String get enterFarmerIpLabel => 'የአቅራቢያ አርሶ አደር IP አድራሻ ያስገቡ፡';

  @override
  String propagatingToIp(String ip) {
    return 'ወደ $ip በመላክ ላይ...';
  }

  @override
  String get propagatedSuccess => 'በተሳካ ሁኔታ ተልኳል!';

  @override
  String failedToConnectIp(String ip) {
    return 'ከ $ip ጋር መገናኘት አልተቻለም';
  }

  @override
  String get sendAction => 'ላክ';

  @override
  String get catCereals => 'ጥራጥሬዎች';

  @override
  String get catPulses => 'አተርና ባቄላ';

  @override
  String get catVegetables => 'አትክልቶች';

  @override
  String get catFruits => 'ፍራፍሬዎች';

  @override
  String get catSpices => 'ቅመማ ቅመሞች';

  @override
  String get catCoffee => 'ቡና';

  @override
  String get catOilSeeds => 'የቅባት እህሎች';

  @override
  String get catTubers => 'ስርወ ምድሮች';

  @override
  String get catLivestock => 'የከብት እርባታ';

  @override
  String get catOthers => 'ሌሎች';

  @override
  String get condFresh => 'ትኩስ';

  @override
  String get condDry => 'ደረቅ';

  @override
  String get condOrganic => 'ተፈጥሯዊ';

  @override
  String get condProcessed => 'የተቀነባበረ';

  @override
  String get condFrozen => 'የበረዶ';

  @override
  String get unitKg => 'ኪሎ';

  @override
  String get unitQuintal => 'ኩንታል';

  @override
  String get unitTon => 'ቶን';

  @override
  String get unitSack => 'ጆንያ';

  @override
  String get unitPiece => 'ፍሬ';

  @override
  String get unitLiter => 'ሊትር';

  @override
  String get addClearPhotosHint => 'ስለ ምርቱ ግልጽ ፎቶዎችን ከተለያዩ አቅጣጫዎች ያክሉ';

  @override
  String get locationNotFound => 'ቦታው አልተገኘም';

  @override
  String get unableToFindLocation => 'ቦታውን ለማግኘት አልተቻለም። እባክዎ እንደገና ይሞክሩ።';

  @override
  String get searchLocationHint => 'ቦታ ይፈልጉ...';

  @override
  String get selectLocationTitle => 'ቦታ ይምረጡ';

  @override
  String get draggingStatus => 'በመጎተት ላይ...';

  @override
  String get fetchingStatus => 'በመፈለግ ላይ...';

  @override
  String get confirmLocationButton => 'ቦታውን አረጋግጥ';

  @override
  String get unknownLocation => 'ያልታወቀ ቦታ';

  @override
  String get catPesticide => 'ፀረ-ተባይ';

  @override
  String get catHerbicide => 'ፀረ-አረም';

  @override
  String get catFungicide => 'ፀረ-ፈንገስ';

  @override
  String get catFertilizer => 'ማዳበሪያ';

  @override
  String get buyInputs => 'የግብርና ግብዓቶችን ይግዙ';

  @override
  String get sellInputs => 'የግብርና ግብዓቶችን ይሽጡ';

  @override
  String get offline => 'ከመስመር ውጭ';

  @override
  String get synced => 'ተ синхሮናይዝድ';

  @override
  String get readMore => 'ተጨማሪ ያንብቡ';

  @override
  String get noAdvice => 'እስካሁን ምንም ምክሮች የሉም።';

  @override
  String get expertAdviceTitle => 'የባለሙያ ምክሮች እና መረጃዎች';

  @override
  String get playVoiceGuide => 'የድምፅ መመሪያውን ያጫውቱ';

  @override
  String get stopVoiceGuide => 'የድምፅ መመሪያውን ያቁሙ';

  @override
  String byAuthor(Object name) {
    return 'በ $name';
  }

  @override
  String get smartAdvisory => 'ብልህ ምክር';

  @override
  String get aiAgronomist => 'AI የግብርና ባለሙያ';

  @override
  String get expertPanel => 'የባለሙያዎች ቡድን';

  @override
  String get cropHealthAnalysis => 'የሰብል ጤና ትንተና';

  @override
  String get excellentCondition => 'በጣም ጥሩ ሁኔታ';

  @override
  String get attentionNeeded => 'ትኩረት ያስፈልጋል';

  @override
  String cropHealthSummary(Object crop, Object status) {
    return 'ባለፉት ፎቶዎችዎ እና በሴንሰር ንባቦችዎ መሰረት፣ የእርስዎ $crop $status እያደገ ነው።';
  }

  @override
  String get optimally => 'በጥሩ ሁኔታ';

  @override
  String get slowerThanExpected => 'ከተጠበቀው በላይ በዝግታ';

  @override
  String get aiRecommendations => 'AI ምክሮች';

  @override
  String get irrigation => 'መስኖ';

  @override
  String moistureLow(Object percent) {
    return 'የአፈር እርጥበት በጣም ዝቅተኛ ነው ($percent%)። መድረቅን ለመከላከል ወዲያውኑ መስኖ ይጀምሩ።';
  }

  @override
  String get moistureOptimal => 'የእርጥበት መጠን ጥሩ ነው። ዛሬ መስኖ አያስፈልግም::';

  @override
  String get nutrients => 'ማዕድናት';

  @override
  String get nutrientsLow =>
      'የNPK መጠን እየቀነሰ ነው። በሚቀጥሉት 2 ቀናት ውስጥ የተፈጥሮ ማዳበሪያ ወይም NPK 15-15-15 ይጠቀሙ።';

  @override
  String get nutrientsStable => 'የማዕድን ሚዛን የተረጋጋ ነው። ክትትልዎን ይቀጥሉ::';

  @override
  String get pestDisease => 'ተባዮች እና በሽታዎች';

  @override
  String get pestHighRisk =>
      'ከፍተኛ እርጥበት ተገኝቷል። የፈንገስ መኖር እድሉ ከፍተኛ ነው። ቅጠሎቹን ለነጠብጣቦች ይፈትሹ::';

  @override
  String get pestLowRisk => 'ዝቅተኛ የተባይ ስጋት ተገኝቷል። የእርሻ ንፅህናን መጠበቅ ይመከራል።';

  @override
  String get urgent => 'አስቸኳይ';

  @override
  String get connectWithExperts => 'ከባለሙያዎች ጋር ይገናኙ';

  @override
  String get getProfessionalGuidance => 'ለእርሻዎ ሙያዊ መመሪያ ያግኙ።';

  @override
  String get requestConsultation => 'ምክር ይጠይቁ';

  @override
  String get online => 'በመስመር ላይ';

  @override
  String get away => 'ተለይቷል';

  @override
  String get crop => 'ሰብል';

  @override
  String get predictedRain => 'የተገመተው፡ 8ሚሜ ዝናብ';

  @override
  String get clearSkies => 'ጥርት ያለ ሰማይ';

  @override
  String get pest => 'ተባይ';

  @override
  String get fungal => 'ፈንገስ';

  @override
  String get weeds => 'አረም';

  @override
  String get soilMoistureProfile => 'የአፈር እርጥበት መገለጫ';

  @override
  String dayLabel(Object day) {
    return 'ቀን $day';
  }

  @override
  String get vegetativeCycle => 'የእድገት ዑደት';

  @override
  String get myCustomLandPlan => 'የእኔ መሬት እቅድ';

  @override
  String get plannerDetail => 'የዕለት ተዕለት/ሳምንታዊ የእርሻ ስራዎችዎን ያስገቡ እና ይከታተሉ።';

  @override
  String get dailyLogBtn => 'ዕለታዊ\nመዝገብ';

  @override
  String get plannerBtn => 'እቅድ አውጪ';

  @override
  String get advisorBtn => 'አማካሪ';

  @override
  String get fertilizeBtn => 'ማዳበሪያ';

  @override
  String get proceedNextDay => 'ወደ ቀጣዩ ቀን ቀጥል';

  @override
  String get tapDeepAnalysis => 'ለጥልቅ AI ትንተና ይጫኑ';

  @override
  String get aiDeepAnalysisTitle => 'ጥልቅ የAI ትንተና';

  @override
  String get gotIt => 'ገባኝ';

  @override
  String get emptyPlanner => 'የእርስዎ እቅድ ባዶ ነው';

  @override
  String get emptyPlannerDetail => 'የራስዎን ዕለታዊ/ሳምንታዊ ተግባራት እዚህ ያክሉ።';

  @override
  String get entryManualPlanTitle => 'ለእጅ እቅድ ግቤት';

  @override
  String get cancel => 'ሰርዝ';

  @override
  String get savePlan => 'እቅድ አስቀምጥ';

  @override
  String get taskTitle => 'የተግባር ርዕስ';

  @override
  String get activityDetail => 'የተግባር ዝርዝር';

  @override
  String get daily => 'ዕለታዊ';

  @override
  String get weekly => 'ሳምንታዊ';

  @override
  String get monthly => 'ወርሃዊ';

  @override
  String get completed => 'ተጠናቋል';

  @override
  String get advicePest => 'በትኩሳት እና በንፋስ ሁኔታዎች ምክንያት የተባይ እንቅስቃሴ እየጨመረ ነው።';

  @override
  String get adviceMoistureLow =>
      'የእርጥበት መጠን ዝቅተኛ ነው። በቅርቡ ዝናብ እንዲዘንብ ተስፋ እናደርጋለን!';

  @override
  String get adviceRainy => 'ተፈጥሯዊ ዝናብ የአፈርን እርጥበት እየሞላው ነው።';

  @override
  String get adviceStable =>
      'ሥነ ምህዳሩ የተረጋጋ ነው። በዝናብ ላይ የተመሰረተ እድገት በጥሩ ሁኔታ ላይ ነው።';

  @override
  String get virtualFarmSimulator => 'ምናባዊ የእርሻ ሲሙሌተር';

  @override
  String get welcomeVirtualFarm => 'ወደ ምናባዊ እርሻዎ እንኳን ደህና መጡ';

  @override
  String get gameIntro =>
      'በመስራት ግብርናን ይማሩ። ውሳኔዎችን ይወስኑ፣ ሀብቶችን ያስተዳድሩ እና AI ምርትዎን እንዴት እንደሚተነብይ ይመልቱ!';

  @override
  String get startNewFarm => 'አዲስ እርሻ ጀምር';

  @override
  String continueFarming(Object day) {
    return 'እርሻውን ይቀጥሉ (ቀን $day)';
  }

  @override
  String get resetStartNew => 'ዳግም አስጀምር እና አዲስ ጀምር';

  @override
  String get myLandsProfile => 'የእኔ መሬቶች መገለጫ';

  @override
  String get noLandsRegistered => 'እስካሁን የተመዘገበ መሬት የለም።';

  @override
  String get startAddingPlot => 'የመጀመሪያውን መሬት በመጨመር ይጀምሩ።';

  @override
  String get registerNewLand => 'አዲስ መሬት ይመዝግቡ';

  @override
  String get landNameHint => 'የመሬት ስም (ለምሳሌ የቤት ውስጥ አትክልት)';

  @override
  String get sizeHectares => 'መጠን (ሄክታር)';

  @override
  String get soilType => 'የአፈር ዓይነት';

  @override
  String get saveLand => 'መሬቱን አስቀምጥ';

  @override
  String get hectares => 'ሄክታር';

  @override
  String get readyPlanting => 'ለመትከል ዝግጁ';

  @override
  String get cycleCompleted => 'ዑደት ተጠናቅቋል';

  @override
  String dayTrackerTitle(Object day) {
    return 'የቀን $day መከታተያ';
  }

  @override
  String get sensorDataCollection => 'በሴንሰር ላይ የተመሰረተ መረጃ መሰብሰብ';

  @override
  String get connectCableDetail => 'የአፈር እና የአካባቢ መረጃን ለማንበብ ገመዱን ያገናኙ';

  @override
  String get soilSensorCable => 'የአፈር ዳሳሽ ገመድ';

  @override
  String get statusConnected => 'ሁኔታ፡ ተገናኝቷል';

  @override
  String get statusDisconnected => 'ሁኔታ፡ አልተገናኘም';

  @override
  String get connect => 'አገናኝ';

  @override
  String get observations => 'ምልከታዎች';

  @override
  String get enterNotes => 'ማስታወሻዎን እዚህ ያስገቡ...';

  @override
  String get saveDailyLog => 'የቀን ምዝግብ ማስታወሻውን አስቀምጥ';

  @override
  String sensorConnectedMsg(Object type) {
    return '✅ ሴንሰር ተገናኝቷል! $type አፈር ተገኝቷል';
  }

  @override
  String get dailyLogSavedMsg => '✅ የቀን ምዝግብ ማስታወሻ በFirestore ውስጥ ተቀምጧል!';

  @override
  String get moisture => 'እርጥበት';

  @override
  String get temp => 'ሙቀት';

  @override
  String get nitrogen => 'ናይትሮጅን';

  @override
  String get phosphorus => 'ፎስፈረስ';

  @override
  String get potassium => 'ፖታሲየም';

  @override
  String get loamy => 'ሎሚ';

  @override
  String get silt => 'ሲልት';

  @override
  String get clay => 'ሸክላ';

  @override
  String get sandy => 'አሸዋማ';

  @override
  String get welcomeToAgrilead => 'እንኳን ወደ አግሪሊድ በደህና መጡ።';

  @override
  String get tapLoginReady => 'ሲዘጋጁ \'ግባ\' የሚለውን ቁልፍ ይጫኑ።';

  @override
  String get productInventoryIntro => 'ይህ የእርስዎ ምርቶች ዝርዝር ነው።';

  @override
  String get startSellingIntro =>
      'ለመሸጥ \'+\' ምልክቱን ወይም \'የመጀመሪያ ምርትዎን ያቅርቡ\' የሚለውን ይጫኑ።';

  @override
  String get registerFieldsIntro => 'ለመመዝገብ እነዚህን መስኮች ይሙሉ::';

  @override
  String get registerFinishIntro => 'ሲጨርሱ \'ይመዝገቡ\' የሚለውን ይጫኑ::';

  @override
  String get dailyTrackerIntro => 'የዛሬውን የእርሻ ስራዎች እዚህ ይመልከቱ::';

  @override
  String get farmMainIntro => 'እርሻዎ እንዴት እየሄደ እንደሆነ ይመልከቱ::';

  @override
  String get gameDashboardIntro => 'ለሰብሎችዎ የ AI ምክር ያግኙ::';

  @override
  String get sellItemIntro => 'ምርትዎን ይግለጹ፣ ዋጋ ይፈርጁ፣ እና ምስሎችን በመጨመር መሸጥ ይጀምሩ::';

  @override
  String get growthJournalIntro => 'የእርሻዎን ታሪክ እዚህ ይገምግሙ::';

  @override
  String get growthJournalDetail => 'እያንዳንዱ ካርድ የእለቱን የአፈር እና የጤና ሁኔታ ያሳያል::';

  @override
  String get seasonalReportIntro => 'ይህ የእርስዎ ወቅታዊ የውጤት ሪፖርት ነው::';

  @override
  String get seasonalReportDetail =>
      'የስራ አፈጻጸምዎን እና የሚጠበቀውን የጥራት ደረጃ እዚህ ይመልከቱ::';

  @override
  String get productListIntro =>
      'ለመግዛት የሚገኙ ዘሮችን፣ ማዳበሪያዎችን እና መሳሪያዎችን እዚህ ይፈልጉ::';

  @override
  String get productListSearchInfo =>
      'የፍለጋ አሞሌውን ወይም ምድቦችን በመጠቀም የሚፈልጉትን ምርት ያግኙ::';

  @override
  String get productListContactInfo => 'ዝርዝሩን ለማየት ወይም ሻጩን ለማነጋገር ምርቱን ይንኩ::';

  @override
  String get marketPricesIntro => 'እዚህ ለሰብሎችዎ የቅርብ የገበያ ዋጋዎችን ማረጋገጥ ይችላሉ።';

  @override
  String get marketPricesGuidance =>
      'ለመሸጥ ምርጥ ጊዜን ለመወሰን ዝቅተኛ እና ከፍተኛ ዋጋዎችን ያወዳድሩ።';

  @override
  String get adviceFeedIntro =>
      'ከግብርና ባለሙያዎች የሚመጡ የቅርብ ጊዜ ምክሮችን እና መረጃዎችን ይቃኙ።';

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
