angular.module("Tune_Core_Search")
	.factory("musicService", function(){
		var music = {"tracks" : [],
						"index" : 0}
		var musicService = {

			getTracks : function(){
				return music.tracks
			},
			getIndex : function(){
				return music.index
			},
			setMusic : function(songs, index){
				!index ? index = 0 : index 
				music.tracks = songs
				music.index = index
				return music
			}

		}
		return musicService
	})