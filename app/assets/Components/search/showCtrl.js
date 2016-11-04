angular.module("Tune_Core_Search")
	.controller("showCtrl", function($scope,musicService,$stateParams,$sce){
		$scope.trustAsHtml = function(html) {
	      return $sce.trustAsHtml(html);
	    }
		$.ajax({
				method: "GET",
				url: "/show",
				dataType: "json",
				data: $stateParams,
				success : function(data){
					$scope.result = data;
					$scope.$apply();
				},
				error : function(data){
					alert("Track wasn't found")
				}
			})


	})