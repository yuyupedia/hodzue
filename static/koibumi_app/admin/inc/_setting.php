<?php

///////////////////////////////////////////////////
// 個人サイト向けひとことフォーム コイブミ Ver1.3.1
// 製作者    ：ガタガタ
// サイト    ：https://do.gt-gt.org/
// ライセンス：MITライセンス
// 全文      ：https://ja.osdn.net/projects/opensource/wiki/licenses%2FMIT_license
// 公開日    ：2020.09.13
// 最終更新日：2022.05.11
//
// このプログラムはどなたでも無償で利用・複製・変更・
// 再配布および複製物を販売することができます。
// ただし、上記著作権表示ならびに同意意志を、
// このファイルから削除しないでください。
///////////////////////////////////////////////////

include_once(dirname(__FILE__).'/_core.php');
$koibumiAdm = new koibumi_admin();
$url = $_SERVER['HTTP_REFERER'];

if (isset($_POST['limitMessage']) && isset($_POST['limitPost']) && isset($_POST['showFavCards'])) {

  $newLimitMessage = $_POST['limitMessage'];
  $newLimitPost = $_POST['limitPost'];
  $newShowFav = $_POST['showFavCards'];
  $newPassword = $password;
  $newNoticeMail = $_POST['notice'];
  $newMailAddress = $_POST['mailaddress'];
  $changepass = false;

  if($_POST['newpw'] !== '') {
    if($_POST['newpw-confirm'] === $_POST['newpw']) {
      $newPassword = htmlspecialchars($_POST['newpw'], ENT_QUOTES, 'UTF-8');
      $changepass = true;
    }
  }

  $setting = array($newPassword, $newLimitMessage, $newLimitPost, $newShowFav, $newNoticeMail, $newMailAddress);

  $fp = fopen(dirname(__FILE__).'/../../datas/setting/config.dat', 'w');

  foreach ($setting as $v) {
    fwrite($fp, $v . "\n");
  }
  // ファイルを閉じる
  fclose($fp);

  if(isset($_POST['ips']) && is_array($_POST['ips'])) {
    $ips = $_POST['ips'];
    $denyIPs = file(dirname(__FILE__).'/../../datas/setting/deny.dat', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($ips as $ip) {
      $key = array_search($ip, $denyIPs);
      array_splice($denyIPs, $key, 1);
    }

    $fp = fopen(dirname(__FILE__).'/../../datas/setting/deny.dat', 'w');

    foreach ($denyIPs as $v) {
      fwrite($fp, $v . "\n");
    }
    // ファイルを閉じる
    fclose($fp);

  }

  if(isset($_POST['words']) && is_array($_POST['words'])) {
    $deletewords = $_POST['words'];
    $NGwords = file(dirname(__FILE__).'/../../datas/setting/NGwords.dat', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($deletewords as $deleteword) {
      $key = array_search($deleteword, $NGwords);
      array_splice($NGwords, $key, 1);
    }

    $fp = fopen(dirname(__FILE__).'/../../datas/setting/NGwords.dat', 'w');

    foreach ($NGwords as $v) {
      fwrite($fp, $v . "\n");
    }
    // ファイルを閉じる
    fclose($fp);

  }

  if(isset($_POST['newNGword']) && $_POST['newNGword'] !== '') {
    $newword = $_POST['newNGword'];
    $NGwords = file(dirname(__FILE__).'/../../datas/setting/NGwords.dat', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    $NGwords[] = $newword;

    $fp = fopen(dirname(__FILE__).'/../../datas/setting/NGwords.dat', 'w');

    foreach ($NGwords as $v) {
      fwrite($fp, $v . "\n");
    }
    // ファイルを閉じる
    fclose($fp);

  }

  if($changepass === true) {
      header("Location:../index.php?mode=logout");
  } else {
    header("Location:$url");
  }
} else {
  header("Location:$url");
}

  ?>
