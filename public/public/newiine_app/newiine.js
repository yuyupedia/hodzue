jQuery(function() {
    'use strict';
  
    var folderpath = '/';
    // newiine_appフォルダが入っているパスを、ドメイン名以下から記入してください。
    // 下記の例に従ってください。
    // var folderpath = '/'; --- http://example.com/newiine_app/の場合
    // var folderpath = '/site/'; --- http://example.com/site/newiine_app/の場合
    // var folderpath = '/site/folder/' --- http://example.com/site/folder/newiine_app/の場合
  
    // ここから下は基本的にいじらないでください

    var ajaxPath = `${location.protocol}//${location.host}${folderpath}newiine_app/_ajax.php`;

    var newIinePathname = location.href;
    var newIinePageTitle = document.title;

  var iineItemButton = [];
  var iineItemButtonArray = [];
  var iineItemButtonName = [];
  var iineItemButtonCount = [];
  var iineItemButton = document.getElementsByClassName('newiine_btn');

  for (var i = 0; i < iineItemButton.length; i++) {
    iineItemButtonArray[i] =  iineItemButton[i];
    iineItemButtonName[i] = iineItemButton[i].dataset.iinename;
    if(iineItemButton[i].getElementsByClassName('newiine_count')[0] !== undefined) {
        iineItemButtonCount[i] = iineItemButton[i].getElementsByClassName('newiine_count')[0];
    } else {
        iineItemButtonCount[i] = null;
    }
  }

  const targets = iineItemButtonArray;

  var newiineUpdateCount = function(h, res) {
    if(iineItemButtonCount[h] !== null) {
      iineItemButtonCount[h].innerHTML = res;
    }
  }

  targets.forEach(function(target, h) {

    jQuery.ajax({
        type: 'GET',
        url : ajaxPath,
        data:{ buttonname: iineItemButtonName[h] }
      }).fail(function(){
        alert('newiine.jsのfolderpathの値を確認して下さい。');
      }).done(function(res){
        var data_arr = JSON.parse(res); //戻り値をJSONとして解析
        newiineUpdateCount(h, data_arr[0]);
        if(data_arr[1] == true) {
          iineItemButtonArray[h].classList.add('newiine_clickedtoday');
        }
        });

      //クリックしたときの処理
    target.addEventListener('click', function(e) {
        e.preventDefault();

        // ajax処理
        jQuery.post(ajaxPath, {
          path: newIinePathname,
          buttonname: iineItemButtonName[h],
          title: newIinePageTitle,
          mode: 'check'
        }).fail(function(){
          alert('koibumi.jsのfolderpathの値を確認して下さい。');
        }).done(function(res){
          if(res === 'upper') {
            console.log(res);
          } else if(res === 'denyIP') {
            console.log(res);
          } else {
            var data_arr = JSON.parse(res); //戻り値をJSONとして解析
            newiineUpdateCount(h, data_arr[0]);
            // アニメーション
            iineItemButtonArray[h].classList.remove('newiine_animate');
            iineItemButtonArray[h].classList.add('newiine_animate');
            setTimeout(function(){
              iineItemButtonArray[h].classList.remove('newiine_animate');
            },500);
            
            iineItemButtonArray[h].classList.add('newiine_clicked');
            var bros = [];
            for (var i = 0; i < iineItemButton.length; i++) {
              if(iineItemButtonName[i] === iineItemButtonName[h] && i !== h) {
                  bros.push(i);
              }
            }
            if(bros.length > 0) {
              bros.forEach((e) => {
                newiineUpdateCount(e, data_arr[0]);
                iineItemButtonArray[e].classList.add('newiine_clicked');
              });
            }

    

          }
        });
    });
});

});