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

header('Content-Type: text/html; charset=UTF-8');

$include = get_included_files();
if (array_shift($include) === __FILE__) {
    die('このファイルへの直接のアクセスは禁止されています。');
}

include_once(dirname(__FILE__).'/admin/inc/_config.php');

class koibumi {

  	// コンストラクタ宣言
  	public function __construct() {

      date_default_timezone_set('Asia/Tokyo');
      $this->today = date("Ymd");
      $this->time = date("H:i:s");

      $this->csvToday = 'datas/'.$this->today.'.csv';

      $this->visitorIP = $_SERVER["REMOTE_ADDR"];
  	}

    public function makeToken() {
      global $limitPost;
      global $limitMessage;

      // 暗号学的的に安全なランダムなバイナリを生成し、それを16進数に変換することでASCII文字列に変換します
      $toke_byte = openssl_random_pseudo_bytes(16);
      $csrf_token = bin2hex($toke_byte);
      // 生成したトークンをセッションに保存します
      $_SESSION['csrf_token'] = $csrf_token;
      $res = array($csrf_token, $limitPost, $limitMessage);
      return json_encode($res);
    }

    public function createMail($postPath, $title, $message) {
      $txt = "";
      $txt .= "コイブミからメッセージが送信されました。" . PHP_EOL . PHP_EOL;
      $txt .= "---------------------------------------" . PHP_EOL;
      $txt .= "送信日時：" .  date("Y/m/d H:i:s")  . PHP_EOL;
      $txt .= "送信元ページ：" . $title . "（" . $postPath . "）" . PHP_EOL;
      $txt .= "以下メッセージ：" . PHP_EOL . PHP_EOL;
      $txt .= html_entity_decode($message) . PHP_EOL . PHP_EOL;
      $txt .= "---------------------------------------" . PHP_EOL;
      return $txt;
    }

    public function sendEveryMail($postPath, $title, $message) {
      global $noticeAddress;
      $to = $noticeAddress;
      $subject = "【コイブミ】メッセージを受信しました";
      $text = $this->createMail($postPath, $title, $message);
      $headers = "From: " . $noticeAddress;
      mail($to, $subject, $text, $headers);
    }


    // URL名がindex.htmlもしくはindex.phpで終わる場合はURLを丸める
    public function checkURL($url) {
      $filenames = array('index.html', 'index.php');
      foreach ($filenames as $filename) {
        if (strpos($url, $filename) !== false) {
          $url = rtrim($url, $filename);
        }
      }
      return $url;
    }

    // タグなどの送信を拒否
    public function entity($txt) {
      $newTxt = htmlentities($txt);
      return $newTxt;
    }

    public function doublequotation($txt) {
      $newTxt = '"' .$txt. '"';
      return $newTxt;
    }

    // PHP5.5以下でもarray_columnに相当する関数を使う
    public function check_column($target_data, $column_key, $index_key = null) {
      if (is_array($target_data) === FALSE || count($target_data) === 0) return false;

      $result = array();
      foreach ($target_data as $array) {
        if (array_key_exists($column_key, $array) === FALSE) continue;
        if (is_null($index_key) === FALSE && array_key_exists($index_key, $array) === TRUE) {
          $result[$array[$index_key]] = $array[$column_key];
          continue;
        }
        $result[] = $array[$column_key];
      }

      if (count($result) === 0) return false;
      return $result;
    }

    public function checkDenyIP($visitorip) {
      $IPs = file('datas/setting/deny.dat', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
      foreach($IPs as $IP) {
        if ($IP === $visitorip) {
          return true;
        }
      }
      return false;
    }

    // 指定された日のデータをチェックする
    public function openCSV($day) {
      $filename = 'datas/'.$day.'.csv';
      if (!file_exists($filename)) {
        // 今日のデータがない場合はfalseを返す
        return false;
      } else {
        // 今日のデータがある場合は、取得した二次元配列から、リクエストの飛んできたページのデータを探す
        $fp = fopen($filename,"r");
        flock($fp, LOCK_EX);
        $csvArray = array();

        // CSVからデータを取得し二次元配列に変換する
        $row = 0;
        while( $ret_csv = fgetcsv( $fp, 0 ) ){
          for($col = 0; $col < count( $ret_csv ); $col++ ){
            $csvArray[$row][$col] = $ret_csv[$col];
          }
          $row++;
        }

        flock($fp, LOCK_UN);
        fclose($fp);

        // 取得したデータを返す
        return $csvArray;
      }
    }

    // 今日の分のデータの中に同一アドレスIPが記録されているか確認する
    public function checkIP($ip) {
      global $limitPost;

      $csvData = $this->openCSV($this->today);
      if($csvData === false) {
        return false;
      }
      $csvKeys = $this->check_column($csvData, 1);
      if($csvKeys === false) {
        return false;
      }

      // 訪問者と同じIPアドレスが、今日の記録のうちにいくつあるかを数える
      $countKeys = count(array_keys($csvKeys, $ip, true));
      if($countKeys >= $limitPost) {
        return true;
      } else {
        return false;
      }
    }

    // NGワードが入っていたら投稿を拒否する
    public function checkNGword($message) {
      $ret = false;
      $NGwords = file('datas/setting/NGwords.dat', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
      foreach($NGwords as $NGword) {
        if(strpos($message, $NGword) !== false){
          $ret = true;
        }
      }
      return $ret;
    }

    // メッセージを記録する
    public function koibumiCount($postPath, $message, $title, $token) {
      global $limitMessage;
      global $noticeMail;
      // スパム防止のトークン確認
      if ($token === $_SESSION['csrf_token']) {

        // 一日の投稿数上限を超える場合は投稿を拒否する
        if ($this->checkIP($this->visitorIP) === true) {
          echo 'ip';
        } elseif ($this->checkNGword($message) === true) {
          echo 'NGword';
        } elseif (mb_strlen($message, 'UTF-8') > $limitMessage) {
          echo 'text';
        } elseif ($this->checkDenyIP($this->visitorIP) === true) {
          echo 'deny';
        } else {
          // そうでなければ投稿を受け付ける
          $newtitle = $this->doublequotation($title);
          $newmessage = $this->doublequotation($message);
          $data = array($postPath, $this->visitorIP, $newtitle, $this->time, $newmessage);
          $fp = fopen($this->csvToday, 'a');
          if(flock($fp, LOCK_EX)) {
            $line = implode(',' , $data);
            fwrite($fp, $line . "\n");
            flock($fp, LOCK_UN);
          }
          fclose($fp);
          echo 'success';
          if ($noticeMail === 'every') {
            $this->sendEveryMail($postPath, $title, $message);
          }
        }
      } else {
        echo 'token';
      }

    }

} // end class koibumi

 ?>
