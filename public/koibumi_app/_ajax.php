<?php

///////////////////////////////////////////////////
// 個人サイト向けひとことフォーム コイブミ Ver1.0.0
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

session_start();
require_once(__DIR__ . '/koibumi.php');

$koibumiApp = new koibumi();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  try {
    if (!isset($_POST['mode'])) {
      throw new \Exception('mode not set!');
    }

    switch ($_POST['mode']) {
      case 'check':
        // URLを丸めてから渡す
        $postPath = $koibumiApp->checkURL($_POST['path']);
        $message = $koibumiApp->entity($_POST['message']);
        $title = $koibumiApp->entity($_POST['title']);
        $token = $_POST['token'];
        return $koibumiApp->koibumiCount($postPath, $message, $title, $token);
    }
  } catch (Exception $e) {
    header($_SERVER['SERVER_PROTOCOL'] . ' 500 Internal Server Error', true, 500);
    echo $e->getMessage();
    exit;
  }
} else {
  try {
    echo $koibumiApp->makeToken();
  } catch (Exception $e) {
    header($_SERVER['SERVER_PROTOCOL'] . ' 500 Internal Server Error', true, 500);
    echo $e->getMessage();
    exit;
  }
}
