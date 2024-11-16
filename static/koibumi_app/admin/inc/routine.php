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

function routineMail($subject, $text) {
  global $noticeAddress;
  $to = $noticeAddress;
  $headers = "From: " . $noticeAddress;
  mail($noticeAddress, $subject, $text, $headers);
}

function dailyreport($day, $datas) {
  $txt = '';
  $txt .= '◆' . date('Y年m月d日', strtotime($day)) . 'のコイブミ＝＝＝＝＝＝＝＝＝＝＝＝' . PHP_EOL . PHP_EOL;

  foreach ($datas as $data) {
    $cards[$data[1]][$data[0]][] = array(
      'message' => html_entity_decode($data[4]),
      'time' => $data[3],
      'title' => $data[2]
    );
  }
  $i = 1;

  foreach($cards as $ip => $card) {
    $txt .= 'コイブミ'.$i.'通目---------------------------' . PHP_EOL;
    foreach ($card as $url => $values) {
      foreach ($values as $k => $value) {
        $txt .= $value['message'] . '（'.$value['time'] . '送信）' . PHP_EOL;
      }
      $txt .= PHP_EOL . '（送信元：'.$value['title'].'　'.$url.'）' . PHP_EOL;
      $txt .= '-----------------------------------------' . PHP_EOL . PHP_EOL;
    } // 送信元URLごとにメッセージを分ける
    $i++;
  } // IPごとにカードを分ける
  $txt .= '＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝' . PHP_EOL . PHP_EOL;

  return $txt;
}

function loginURL() {
  // $url = (empty($_SERVER['HTTPS']) ? 'http://' : 'https://') . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI'];
  // $url = str_replace('inc/routine.php', '', $url);
  // $txt = '管理画面ログイン：' . $url;
  $txt = '';
  return $txt;
}

if($noticeMail === 'everyday') {
  $yesterday = date('Ymd', strtotime('-1 day'));
  $datas = $koibumiAdm->openCSV($yesterday);
  if($datas === false) {
    return;
  } else {
    $txt = '';
    $txt .= dailyreport($yesterday, $datas);

    $txt .= loginURL();

    routineMail('【コイブミ】デイリーレポートの送付', $txt);
  }
} elseif($noticeMail === 'weekly') {
  $end = date('Ymd', strtotime('-1 day'));
  $start = date('Ymd', strtotime('-1 week'));
  $diff = (strtotime($end) - strtotime($start)) / ( 60 * 60 * 24);
  $datas = array();
  for($i = 0; $i <= $diff; $i++) {
    $day = date('Ymd', strtotime($start . '+' . $i . 'days'));
    if($koibumiAdm->openCSV($day) !== false) {
      $datas[$day] = $koibumiAdm->openCSV($day);
    }
  }
  // var_dump($datas);
  $txt = '';
  $txt .= date('Y年m月d日', strtotime($start)) . '～' . date('Y年m月d日', strtotime($end)) . 'のウィークリーレポート' . PHP_EOL . PHP_EOL;

  foreach ($datas as $day => $data) {
    $txt .= dailyreport($day, $data);
  }

  $txt .= loginURL();

  routineMail('【コイブミ】ウィークリーレポートの送付', $txt);

} elseif($noticeMail === 'monthly') {
  $end = date('Ymd', strtotime('-1 day'));
  $start = date('Ymd', strtotime('-1 month'));
  $diff = (strtotime($end) - strtotime($start)) / ( 60 * 60 * 24);
  $datas = array();
  for($i = 0; $i <= $diff; $i++) {
    $day = date('Ymd', strtotime($start . '+' . $i . 'days'));
    if($koibumiAdm->openCSV($day) !== false) {
      $datas[$day] = $koibumiAdm->openCSV($day);
    }
  }
  // var_dump($datas);
  $txt = '';
  $txt .= date('Y年m月d日', strtotime($start)) . '～' . date('Y年m月d日', strtotime($end)) . 'のマンスリーレポート' . PHP_EOL . PHP_EOL;

  foreach ($datas as $day => $data) {
    $txt .= dailyreport($day, $data);
  }

  $txt .= loginURL();

  routineMail('【コイブミ】マンスリーレポートの送付', $txt);
}
