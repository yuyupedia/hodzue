function submitDelete() {
    var flag = confirm ( "メッセージを削除しますか？\n削除したメッセージは元に戻せません。");
    return flag;
}

function submitSetting() {
  var newpw = document.getElementById('newpw').value;
  var confirmPw = document.getElementById('confirm-pw').value;
  var buttons = document.getElementsByName('notice');
  var mailaddress = document.getElementById('mailaddress').value;

  for ( var notice="", i=buttons.length; i--; ) {
  	if ( buttons[i].checked ) {
  		var notice = buttons[i].value ;
  		break ;
  	}
  }

  if (newpw != '' && confirmPw == '') {
    alert('新パスワードは確認のため二度入力してください。');
    return false;
  } else if(newpw !== confirmPw) {
    alert('新パスワードが一致しません。再度入力してください。');
    return false;
  }

  if (notice != 'none' && mailaddress == '') {
    alert('メッセージ通知を受信するメールアドレスを入力して下さい。');
    return false;
  }

    var flag = confirm ( "設定を変更しますか？");
    return flag;
}

function submitArchive() {
  var check = false; // 選択されているか否かを判定する変数
  var archiveForm = document.getElementsByName('datas[]');

  for (var i = 0; i < archiveForm.length; i++) {
    // i番目のチェックボックスがチェックされているかを判定
    if (archiveForm[i].checked) {
      check = true;
    }
  }

  // 何も選択されていない場合の処理
  if (check == false) {
    alert('メッセージが選択されていません。');
    return false;
  } else {
    var selection = document.getElementById('selection').value;
    if (selection == 'delete') {
      var flag = confirm('メッセージをすべて削除しますか？\n削除したメッセージは元に戻せません。');
      return flag;
    }
    if (selection == 'deny') {
      var flag = confirm('選択したメッセージの送信元IPからの\n今後の投稿をすべて拒否しますか？');
      return flag;
    }
  }

}
