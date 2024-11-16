<?php

///////////////////////////////////////////////////
// いいねボタン改 Ver0.1.0
// 製作者    ：ガタガタ
// サイト    ：https://do.gt-gt.org/
// ライセンス：MITライセンス
// 全文      ：https://ja.osdn.net/projects/opensource/wiki/licenses%2FMIT_license
// 公開日    ：2021.12.30
//
// このプログラムはどなたでも無償で利用・複製・変更・
// 再配布および複製物を販売することができます。
// ただし、上記著作権表示ならびに同意意志を、
// このファイルから削除しないでください。
///////////////////////////////////////////////////

include_once(dirname(__FILE__).'/_core.php');
$koibumiAdm = new newiine_admin();
$url = $_SERVER['HTTP_REFERER'];

if (isset($_POST['limitPost'])) {

  $newLimitPost = $_POST['limitPost'];
  $newPassword = $password;
  $changepass = false;

  if($_POST['newpw'] !== '') {
    if($_POST['newpw-confirm'] === $_POST['newpw']) {
      $newPassword = htmlspecialchars($_POST['newpw'], ENT_QUOTES, 'UTF-8');
      $changepass = true;
    }
  }

  $setting = array($newPassword, $newLimitPost);

  $fp = fopen(dirname(__FILE__).'/../../datas/setting/config.dat', 'w');

  foreach ($setting as $v) {
    fwrite($fp, $v . "\n");
  }
  // ファイルを閉じる
  fclose($fp);

  if($changepass === true) {
      header("Location:../index.php?mode=logout");
  } else {
    header("Location:$url");
  }
} 

if($_POST['banIP'] !== '') {

  $newBanIP = $_POST['banIP'];

  $fp = fopen(dirname(__FILE__).'/../../datas/setting/deny.dat', 'a');
  
  fwrite($fp, $newBanIP . "\n");
  // ファイルを閉じる
  fclose($fp);

  if($changepass === true) {
      header("Location:../index.php?mode=logout");
  } else {
    header("Location:$url");
  }

} 

  ?>
