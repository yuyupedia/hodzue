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

session_start();
require_once(__DIR__ . '/newiine.php');

$newiineApp = new newiine();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  try {
    if (!isset($_POST['mode'])) {
      throw new \Exception('mode not set!');
    }

    switch ($_POST['mode']) {
      case 'check':
        // URLを丸めてから渡す
        $postPath = $newiineApp->checkURL($_POST['path']);
        $btnName = $newiineApp->entity($_POST['buttonname']);
        $title = $newiineApp->entity($_POST['title']);
        return $newiineApp->newiineCount($postPath, $btnName, $title);
    }
  } catch (Exception $e) {
    header($_SERVER['SERVER_PROTOCOL'] . ' 500 Internal Server Error', true, 500);
    echo $e->getMessage();
    exit;
  }
} else {
  try {
    return $newiineApp->newiineSum($_GET['buttonname']);
  } catch (Exception $e) {
    header($_SERVER['SERVER_PROTOCOL'] . ' 500 Internal Server Error', true, 500);
    echo $e->getMessage();
    exit;
  }
}
