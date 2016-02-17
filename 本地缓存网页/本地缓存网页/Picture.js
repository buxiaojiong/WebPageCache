 (function(){
  
  var allImg = document.querySelectorAll("#contentArticle img");
 
  var arrayImg=[];
  for (var i = 0; i < allImg.length; i++) {
		arrayImg.push(allImg[i].src);
		(function(i) {
         allImg[i].addEventListener('click', function() {
                                    var jsonImg={
                                    images:arrayImg,
                                    index:i
                                    };
                                   // alert(encodeURIComponent(JSON.stringify(jsonImg)));
                                    window.location.href='openImg://'+escape(JSON.stringify(jsonImg));
                                    })
         })(i)
  }
  var protocolFormat="relatedread://"+"!--data--!";
  
  //
  document.getElementById("relatedArticlesWrapper").style.display="block";
  
  var articleItems=document.getElementById("relatedArticlesList").querySelectorAll(".articleItem");
  var jsonData={};
  for(var i=0;i<articleItems.length;i++){
  articleItems[i].addEventListener("click",function(e){
                                   jsonData={
                                   "id":e.currentTarget.getAttribute("articleId")*1,
                                   "title":e.currentTarget.getAttribute("articleTitle"),
                                   "summary":e.currentTarget.getAttribute("articleSummary")
                                   };
                                   console.log(escape(JSON.stringify(jsonData)))
                                   window.location=protocolFormat.replace(new RegExp("!--data--!","g"),escape(JSON.stringify(jsonData)));
                                   });
  }

  })()