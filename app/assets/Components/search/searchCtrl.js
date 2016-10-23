angular.module("Tune_Core_Search")
	.controller("searchCtrl", function($scope){

		$scope.submit = function(formData){
			$.ajax({
				method: "GET",
				url: "/resource",
				dataType: "json",
				data: formData
			})

		}
	});


	