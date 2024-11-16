$(function() {
  'use strict';
  
  var koibumiMessageVisibleTime = 6000;
  // お礼メッセージを表示する時間の長さを変更できます（単位はミリ秒。6000＝6秒）

  // ここから下は基本的にいじらないでください

  // 自分の設置されているURLの取得
  var root;
  var scripts = document.getElementsByTagName("script");
  var i = scripts.length;
  while (i--) {
      var match = scripts[i].src.match(/(^|.*\/)koibumi\.js$/);
      if (match) {
          root = match[1];
          break;
      }
  }

  var ajaxPath = root+'_ajax.php';

  var pathname = location.href;
  var pageTitle = document.title;
  var token = document.getElementById('koibumi_token');
  var limitIP = document.getElementById('koibumi_limitIP');
  var limitMessage = document.getElementById('koibumi_limitMessage');
  var alert = document.getElementById('koibumi_alert');
  var thanks = document.getElementById('koibumi_thanks');
  var data_arr;

  var koibumiFadeout = function() {
    setTimeout(function(){
      alert.classList.add('koibumifadeout');
    }, 4000);
    setTimeout(function(){
      alert.style.display = "none";
      if(alert.classList.contains('alert')) {
        alert.classList.remove('alert','koibumifadeout');
      } else if(alert.classList.contains('success')) {
        alert.classList.remove('success','koibumifadeout');
      }
    }, 5000);
   }

  var koibumiFadeoutT = function() {
    setTimeout(function(){
      thanks.classList.add('koibumifadeout');
    }, koibumiMessageVisibleTime);
    setTimeout(function(){
      thanks.style.display = "none";
      thanks.classList.remove('koibumifadeout');
    }, koibumiMessageVisibleTime + 1000);
   }

  $(document).ready( function(){
    $.ajax({
      type: 'GET',
      url : ajaxPath,
    }).fail(function(){
      alert('お使いのサーバーでPHPが使えるかご確認ください。');
    }).done(function(res){
      data_arr = JSON.parse(res);
      token.value = data_arr[0];
      limitIP.innerHTML = data_arr[1];
      limitMessage.innerHTML = data_arr[2];
    });
  });

  // update
  $(document).on('click', '#koibumi_btn', function(e) {
	e.preventDefault();
  if($('#koibumi_text').val() == '') {
    alert.innerHTML = 'メッセージを入力してください';
    alert.classList.add('alert');
    alert.style.display = "block";
    koibumiFadeout();
    alert.classList('');
    return;
  }
  var message = $('#koibumi_text').val();
    // ajax処理
    $.post(ajaxPath, {
      path: pathname,
      title: pageTitle,
      message: message,
      token: token.value,
      mode: 'check'
    }).fail(function(){
      alert('お使いのサーバーでPHPが使えるかご確認ください。');
    }).done(function(res){
      switch (res) {
        case 'token':
          alert.innerHTML = 'トークンが一致しません';
          alert.classList.add('alert');
          alert.style.display = "block";
          koibumiFadeout();
          break;
        case 'deny':
          alert.innerHTML = '投稿を受け付けることができません';
          alert.classList.add('alert');
          alert.style.display = "block";
          koibumiFadeout();
          break;
        case 'NGword':
          alert.innerHTML = '投稿を受け付けることができません';
          alert.classList.add('alert');
          alert.style.display = "block";
          koibumiFadeout();
          break;
        case 'ip':
          alert.innerHTML = '一日の上限送信回数を超えています';
          alert.classList.add('alert');
          alert.style.display = "block";
          koibumiFadeout();
          break;
        case 'text':
        var l = document.getElementById('koibumi_text').value.length;
          alert.innerHTML = '文字数が' + limitMessage.innerHTML + '文字を超えています（' + l  +'文字）';
          alert.classList.add('alert');
          alert.style.display = "block";
          koibumiFadeout();
          break;
        case 'success':
          thanks.style.display = "block";
          koibumiFadeoutT();
          $('#koibumi_text').val('');
          break;
        default:
          alert.innerHTML = '何か問題が起きたようです';
          alert.classList.add('alert');
          alert.style.display = "block";
          koibumiFadeout();
      }
    });
});
});
