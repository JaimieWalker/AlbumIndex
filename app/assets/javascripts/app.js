var app = angular.module("Tune_Core_Search",
	["ngResource","ui.router","templates"]);
app.config(function($stateProvider, $urlRouterProvider, $locationProvider){
	$locationProvider.html5Mode(true);
	$stateProvider
		.state("home", {
			url: '/',
			templateUrl: "search/index.html",
			controller: "searchCtrl"
		})

})