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

header('Content-Type: text/html; charset=UTF-8');

$include = get_included_files();
if (array_shift($include) === __FILE__) {
    die('このファイルへの直接のアクセスは禁止されています。');
}

include_once(dirname(__FILE__).'/admin/inc/_config.php');

class newiine {

    // コンストラクタ宣言
    public function __construct() {

    date_default_timezone_set('Asia/Tokyo');
    $this->today = date("Y/m/d");
    $this->time = date("H:i:s");

    $this->visitorIP = $_SERVER["REMOTE_ADDR"];

    global $limitPost;

    $this->iineLimit = $limitPost;
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

      private function checkTodaysCount($btnName) {
        list($num, $csvArray) = $this->openCSV($btnName);
        if ($num === false || $csvArray[$num][5] < $this->iineLimit) {
            return false;
        } else {
            return true;
        }
      }

    // CSVを開いて当該いいねボタンに関するデータを引っ張り出す関数
    public function openCSV($btnName, $mode = null, $URL = null) {
      if($mode === null) {
        $filename = 'datas/'.$btnName.'.csv';
      } else {
        $filename = dirname(__FILE__, 1). '/datas/'.$btnName.'.csv';
      }
        if(file_exists($filename)) {
          $fp = fopen($filename, "r");
          $csvArray = array();
    
          // CSVからデータを取得し二次元配列に変換する
          $row = 0;
          while( $ret_csv = fgetcsv( $fp, 0 ) ){
            for($col = 0; $col < count( $ret_csv ); $col++ ){
              $csvArray[$row][$col] = $ret_csv[$col];
            }
            $row++;
          }
          fclose($fp);
    
          // データがある場合は、取得した二次元配列から、
          // リクエストの飛んできたいいねボタンのデータを探す。なければfalseを返す
          $num = false;
          if($mode === null) {
            foreach ($csvArray as $key => $value) {
              if($value[2] === $this->visitorIP && $value[3] === $this->today && $value[0] === $URL) {
                $num = $key;
              }
            }
          }

        } else {
          $num = false;
          $csvArray = false;
        }

        return array($num, $csvArray);
      }
      
      // CSVファイルに二次元配列を上書きする関数
    private function rewriteCSV($btnName, $csvArray, $num) {
        $filename = 'datas/'.$btnName.'.csv';
        $fp = fopen($filename, 'w');
  
        // 二次元配列を１行ずつCSV形式に直して書き込む
        foreach ($csvArray as $key => $v) {
            if ($key !== $num) {
                  $v[0] = $this->doublequotation($v[0]);
                  $v[1] = $this->doublequotation($v[1]);
            }
          $line = implode(',' , $v);
          fwrite($fp, $line . "\n");
        }
        // ファイルを閉じる
        fclose($fp);
    }

    // いいね数を増やす関数！
    public function newiineCount($postPath, $btnName, $title) {

      // IPアドレスが拒否されていれば、いいねを拒否する
      $IPs = file('datas/setting/deny.dat');
      // var_dump($IPs);
      $checkIP = false;
      foreach($IPs as $IP) {
        if($this->visitorIP === trim($IP)) {
          $checkIP = true;
        }
      }

      if($checkIP === true) {
        echo 'denyIP';
      } else {
        $newtitle = $this->doublequotation($title);
        $newURL = $this->doublequotation($postPath);
        $filename = 'datas/'.$btnName.'.csv';
  
        list($num, $csvArray) = $this->openCSV($btnName, null, $postPath);
        if($num === false) {
            // 今日はまだいいねしていない場合は新しい行で受け付ける
            $data = array($newURL, $newtitle, $this->visitorIP, $this->today, $this->time, 1);
            $fp = fopen($filename, 'a');
            if(flock($fp, LOCK_EX)) {
            $line = implode(',' , $data);
            fwrite($fp, $line . "\n");
            flock($fp, LOCK_UN);
            }
            fclose($fp);
            $sum = $this->newiineSum($btnName);
            echo $sum;
        } elseif($num !== false && $this->checkTodaysCount($btnName) === false) {
            // 今日はいいねしているけど１日上限数未満の場合は上書きして受け付ける
            $count = $csvArray[$num][5];
            $newCount = $count + 1;
            $newdata = array($newURL, $newtitle, $this->visitorIP, $this->today, $this->time, $newCount);
            
            $addArray = array($newdata);
            array_splice($csvArray, $num, 1, $addArray);
  
            $this->rewriteCSV($btnName, $csvArray, $num);
            $sum = $this->newiineSum($btnName);
            echo $sum;
        } else {
            // それ以外の場合は受け付けない
            echo 'upper';
        }
      }

    }

    // いいねボタンの総いいね数を返す関数
    public function newiineSum($btnName) {
        list($num, $csvArray) = $this->openCSV($btnName);
        $sum = 0;
        $today = false;
        if($csvArray !== false) {
            foreach ($csvArray as $key => $value) {
                $sum = $sum + $value[5];
                if($value[2] === $this->visitorIP) {
                  $today = true;
                }
            }
        }

        $ret_array = array($sum, $today);
        $datas = json_encode($ret_array);
        
        echo $datas;
    }

}

?>