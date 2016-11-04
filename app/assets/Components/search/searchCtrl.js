angular.module("Tune_Core_Search")
	.controller("searchCtrl", function($scope,musicService){
		$scope.index = 0;


		if (musicService.getTracks().length === 0) {
			$.ajax({
				method: "GET",
				url: "/random",
				dataType: "json",
				success : function(data){
					musicService.setMusic(data);
					if (musicService.getTracks().length > 0) {
					}
					 $scope.songs = musicService.getTracks();
					 $scope.$apply()
				},
				error : function(data){
					alert("Track wasn't found")
				}
			})
		}else {
			$scope.songs = musicService.getTracks()
		}
		


		$scope.submit = function(formData){
			$.ajax({
				method: "GET",
				url: "/resource",
				dataType: "json",
				data: formData,
				success : function(data){
					musicService.setMusic(data);
					 $scope.songs = musicService.getTracks();
					 $scope.$apply()
				},
				error : function(data){
					alert("Track wasn't found")
				}
			})


		}
	});


	