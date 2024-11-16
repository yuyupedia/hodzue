<?php

$include = get_included_files();
if (array_shift($include) === __FILE__) {
    die('URLを確認してください。');
}

$settings = file(dirname(__FILE__).'/../../datas/setting/config.dat', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
//  --------------------------------------------  //


// ログインパスワード ※必ず変更してください！
$password = $settings[0];

// メッセージの文字数上限
$limitMessage = $settings[1];

// 同一IPアドレスが一日のうちに連続投稿できる上限件数
$limitPost = $settings[2];

// お気に入りの表示件数
$showFavCards = $settings[3];

if(isset($settings[4]) === false) {
  $noticeMail = 'none';
} else {
  $noticeMail = $settings[4];
}

if(isset($settings[5]) === false) {
  $noticeAddress = '';
} else {
  $noticeAddress = $settings[5];
}

?>
