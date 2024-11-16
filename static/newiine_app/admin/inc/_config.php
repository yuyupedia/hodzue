<?php

$include = get_included_files();
if (array_shift($include) === __FILE__) {
    die('URLを確認してください。');
}

$settings = file(dirname(__FILE__).'/../../datas/setting/config.dat', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
//  --------------------------------------------  //


// ログインパスワード ※必ず変更してください！
$password = $settings[0];

// 同一IPアドレスが一日のうちに連続投稿できる上限件数
$limitPost = $settings[1];

?>
