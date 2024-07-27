const String unsplashAccessKey = "7r4n13EnQiH4ToE-VJg9qqfATGT_5UAfsLLrHi31Gdg";
const baseurl = "https://api.unsplash.com/";
const getRandomPhoto = "photos/random";

const api = "$baseurl$getRandomPhoto?client_id=$unsplashAccessKey&orientation=portrait";

const api2 = "$baseurl/search/photos?client_id=$unsplashAccessKey&page=1&query";