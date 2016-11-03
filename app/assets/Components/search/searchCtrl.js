angular.module("Tune_Core_Search")
	.controller("searchCtrl", function($scope){
		$scope.songs;
		$scope.submit = function(formData){
			$.ajax({
				method: "GET",
				url: "/resource",
				dataType: "json",
				data: formData,
				success : function(data){
					 $scope.songs = data;
					 $scope.$apply()
					debugger
				},
				error : function(data){

				}
			})

		}
	});


	