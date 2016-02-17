function setImgUrl(oldUrl,newUrl){
    var imgs=document.querySelectorAll("img[src="+oldUrl+"]");
   
    if(imgs.length>0){
       
        imgs[0].setAttribute("src",newUrl);
    }
}
