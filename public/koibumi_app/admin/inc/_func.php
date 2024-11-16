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

if (isset($_POST['datas']) && is_array($_POST['datas'])) {
      $datas = $_POST['datas'];

      if ($_POST['selection'] === 'delete') {
        rsort($datas);

        foreach ($datas as $data) {
          $arr = array();
          $arr = explode('-', $data);
          list($day, $num) = $arr;

          $resData = $koibumiAdm->deleteData($day, $num, 'default');
          $favfilename = dirname(__FILE__). '/../../datas/fav/'.$day.'.csv';

          if(file_exists($favfilename)) {
            $favDatas = $koibumiAdm->openCSV($favfilename);
            $key = array_search($resData, $favDatas);
            if($key !== false) {
              $resData = $koibumiAdm->deleteData($day, $key, 'fav', $resData);
            }
          }
        }
      } elseif ($_POST['selection'] === 'favorite') {

        // favフォルダがなければ作成する
        $dirpath = '../../datas/fav';
        if (!file_exists($dirpath)) {
          mkdir($dirpath, 0777);
        }

        foreach ($datas as $data) {
          $arr = array();
          $arr = explode('-', $data);
          list($day, $num) = $arr;

          $arr = $koibumiAdm->openCSV($day);
          $fav = $arr[$num];
          $filename = dirname(__FILE__). '/../../datas/fav/'.$day.'.csv';

          if(file_exists($filename)) {
            $favDatas = $koibumiAdm->openCSV($filename);
            $key = array_search($fav, $favDatas);
            if($key !== false) {
              continue;
            }
          }

          $fp = fopen($filename, 'a');
          $fav[2] = $koibumiAdm->doublequotation($fav[2]);
          $fav[4] = $koibumiAdm->doublequotation($fav[4]);
          $line = implode(',' , $fav);
          fwrite($fp, $line . "\n");
          fclose($fp);
        }

      } elseif($_POST['selection'] === 'defav') {
        rsort($datas);

        foreach ($datas as $data) {
          $arr = array();
          $arr = explode('-', $data);
          list($day, $num) = $arr;

          $defDatas = $koibumiAdm->openCSV($day);
          $retData = $defDatas[$num];

          $resData = $koibumiAdm->deleteData($day, $num, 'fav', $retData);
        }

      } elseif($_POST['selection'] === 'deny') {
        foreach ($datas as $data) {
          $arr = array();
          $arr = explode('-', $data);
          list($day, $num) = $arr;
          $denyfilename = dirname(__FILE__). '/../../datas/setting/deny.dat';

          $line = $koibumiAdm->openCSV($day);
          $denyIP = $line[$num][1];

          $check = false;
          $IPs = file($denyfilename, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
          foreach($IPs as $IP) {
            if ($IP === $denyIP) {
              $check = true;
            }
          }

          // 既に同一IPが拒否されていなければ、拒否IPを追加する
          if(!$check) {
            $fp = fopen($denyfilename, 'a');
            fwrite($fp, $denyIP . "\n");
            fclose($fp);
          }
        }
      }

      header("Location:$url");

    } elseif(isset($_POST['data']) && isset($_POST['mode'])) {
      $data = $_POST['data'];

      if($_POST['mode'] === 'defav') {
        $arr = array();
        $arr = explode('-', $data);
        list($day, $num) = $arr;
        $defDatas = $koibumiAdm->openCSV($day);
        $retData = $defDatas[$num];

        $resData = $koibumiAdm->deleteData($day, $num, 'fav', $retData);
      } elseif($_POST['mode'] === 'delete') {
          $arr = array();
          $arr = explode('-', $data);
          list($day, $num) = $arr;

          $resData = $koibumiAdm->deleteData($day, $num, 'default');
          $favfilename = dirname(__FILE__). '/../../datas/fav/'.$day.'.csv';

          if(file_exists($favfilename)) {
            $favDatas = $koibumiAdm->openCSV($favfilename);
            $key = array_search($resData, $favDatas);
            if($key !== false) {
              $resData = $koibumiAdm->deleteData($day, $key, 'fav', $resData);
            }
          }
        } elseif($_POST['mode'] === 'favorite') {

          // favフォルダがなければ作成する
          $dirpath = '../../datas/fav';
          if (!file_exists($dirpath)) {
            mkdir($dirpath, 0777);
          }

          $arr = array();
          $arr = explode('-', $data);
          list($day, $num) = $arr;

          $arr = $koibumiAdm->openCSV($day);
          $fav = $arr[$num];
          $fav[2] = $koibumiAdm->doublequotation($fav[2]);
          $fav[4] = $koibumiAdm->doublequotation($fav[4]);

          $filename = dirname(__FILE__). '/../../datas/fav/'.$day.'.csv';

          $fp = fopen($filename, 'a');

          $line = implode(',' , $fav);
          fwrite($fp, $line . "\n");
          fclose($fp);
        }

      header("Location:$url");

} else {
    header("Location:$url");
}



  ?>
