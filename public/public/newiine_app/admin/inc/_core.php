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

$include = get_included_files();
if (array_shift($include) === __FILE__) {
    die('このファイルへの直接のアクセスは禁止されています。');
}

include_once(dirname(__FILE__).'/_config.php');
include_once(dirname(__FILE__).'/../../newiine.php');

class newiine_admin extends newiine {

  	// コンストラクタ宣言
  	public function __construct() {

      date_default_timezone_set('Asia/Tokyo');
      $this->today = date("Y/m/d");
      $this->yesterday = date('Y/m/d', strtotime('-1 day'));

  	}

    private function getAllDatas() {
      $filenames = glob(dirname(__FILE__, 3). '/datas/*.csv');
      $allDatas = Array();
      
      foreach ($filenames as $key => $filename) {
        $newFileName = basename($filename, '.csv');
        $data = $this->openCSV($newFileName, true);
        $allDatas[$newFileName] = $data[1];
      }

      return $allDatas;
      
    }

    // いいねボタンの総いいね数を返す関数
    public function newiineSum($btnName, $day = null) {
      $sum = 0;
      if($day === null) {
        list($num, $csvArray) = $this->openCSV($btnName, true);
        if($csvArray !== false) {
            foreach ($csvArray as $value) {
                $sum = $sum + $value[5];
            }
        }
      } else {

      }
        
        return $sum;
    }

    public function recentlyReport() {
      $allDatas = $this->getAllDatas();
      $selectedDatas = array();
      $sums = array();
      $todaySums = array();
      $yesterdaySums = array();

      // それぞれのボタンが今日もしくは昨日いいねされたか判定
      foreach ($allDatas as $key => $datas) {
        $todaySums[$key] = 0;
        $yesterdaySums[$key] = 0;
        foreach ($datas as $data) {
          if($data[3] === $this->today || $data[3] === $this->yesterday) {
            $selectedDatas[$key] = $data;
            if($data[3] === $this->today){
              $todaySums[$key] = $todaySums[$key] + $data[5];
            } elseif($data[3] === $this->yesterday) {
              $yesterdaySums[$key] = $yesterdaySums[$key] + $data[5];
            }
          }
        }
        if(!empty($selectedDatas[$key])) {
          $sums[$key] = $this->newiineSum($key);
        }
      }

      // 今日もしくは昨日いいねされたもののデータだけを返す
      // それぞれのボタンの直近のいいねデータを整理
      $html = '';
      if(empty($selectedDatas)) {
        $html .= '<p>データがありません。</p>';
      } else {
        $html .= '<table>';
        $html .= '<thead>';
        $html .= '  <tr>';
        $html .= '    <th>ボタン名</th>';
        $html .= '    <th>設置アドレス</th>';
        $html .= '    <th>いいね数</th>';
        $html .= '  </tr>';
        $html .= '</thead>';
        $html .= '<tbody>';

        foreach ($selectedDatas as $key => $data) {
          
        $tmp = array();
        $array_result = array();

          foreach( $allDatas[$key] as $value ){
              // 配列に値が見つからなければ$tmpに格納
              if( !in_array( $value[0], $tmp ) ) {
               $tmp[] = $value[0];
               $array_result[] = $value;
              }
          }

          $html .= '<tr>';
          $html .= '<th>'.$key.'</th>';
          $html .= '<td>';
          foreach ($array_result as $page) {
            # code...
            $html .= '<a href="'.$page[0].' "target="_blank">'.$page[0].'<span style="font-size:90%;">（'.$page[1].'）</span></a>';
            if($page !== end($array_result)){
                $html .= '<br>';
            }
          }
          $html .= '</td>';
          $html .= '  <td>';
          $html .= '   今日：'.$todaySums[$key].'<br>';
          $html .= '    昨日：'.$yesterdaySums[$key].'<br>';
          $html .= '   合計：'.$this->newiineSum($key);
          $html .= ' </td>';
          $html .= ' </tr>';
        }
        $html .= '</tbody>';
        $html .= '</table>';

      }

      echo $html;
    }

    public function allBtnReport() {
      $allDatas = $this->getAllDatas();
      $selectedDatas = array();
      $sums = array();
      $todaySums = array();
      $yesterdaySums = array();

      // それぞれのボタンが今日もしくは昨日いいねされたか判定
      foreach ($allDatas as $key => $datas) {
        $todaySums[$key] = 0;
        $yesterdaySums[$key] = 0;
        foreach ($datas as $data) {
          if($data[3] === $this->today || $data[3] === $this->yesterday) {
            $selectedDatas[$key] = $data;
            if($data[3] === $this->today){
              $todaySums[$key] = $todaySums[$key] + $data[5];
            } elseif($data[3] === $this->yesterday) {
              $yesterdaySums[$key] = $yesterdaySums[$key] + $data[5];
            }
          }
        }
        if(!empty($selectedDatas[$key])) {
          $sums[$key] = $this->newiineSum($key);
        }
      }

      // 今日もしくは昨日いいねされたもののデータだけを返す
      // それぞれのボタンの直近のいいねデータを整理
      $html = '';
      if(empty($allDatas)) {
        $html .= '<p>データがありません。</p>';
      } else {
        $html .= '<table>';
        $html .= '<thead>';
        $html .= '  <tr>';
        $html .= '    <th>ボタン名</th>';
        $html .= '    <th>設置アドレス</th>';
        $html .= '    <th>いいね数</th>';
        $html .= '  </tr>';
        $html .= '</thead>';
        $html .= '<tbody>';

        foreach ($allDatas as $key => $data) {
          
        $tmp = array();
        $array_result = array();

          foreach( $allDatas[$key] as $value ){
              // 配列に値が見つからなければ$tmpに格納
              if( !in_array( $value[0], $tmp ) ) {
               $tmp[] = $value[0];
               $array_result[] = $value;
              }
          }

          $html .= '<tr>';
          $html .= '<th>'.$key.'</th>';
          $html .= '<td>';
          foreach ($array_result as $page) {
            # code...
            $html .= '<a href="'.$page[0].' "target="_blank">'.$page[0].'<span style="font-size:90%;">（'.$page[1].'）</span></a>';
            if($page !== end($array_result)){
                $html .= '<br>';
            }
          }
          $html .= '</td>';
          $html .= '  <td>';
          $html .= '   今日：'.$todaySums[$key].'<br>';
          $html .= '    昨日：'.$yesterdaySums[$key].'<br>';
          $html .= '   合計：'.$this->newiineSum($key);
          $html .= ' </td>';
          $html .= ' </tr>';
        }
        $html .= '</tbody>';
        $html .= '</table>';

      }

      echo $html;
    }

    // いいね拒否しているIPアドレスを表示する関数
    public function denyIP() {
      $html = '';
      
      $IPs = file(dirname(__FILE__).'/../../datas/setting/deny.dat');

      if(empty($IPs)) {
        $html .= '<p class="memo">現在いいねを拒否しているIPアドレスはありません。<br>';
        $html .= '※いいねした人のIPアドレスを調べる方法は<a href="tips.php#how_to_add_IP">こちら</a></p>';
      } else {
        $html .= '<p class="memo">現在いいねを拒否しているIPアドレス：<br>';
        foreach ($IPs as $IP) {
          $html .= $IP . '<br>';
        }
        $html .= '※いいねした人のIPアドレスを調べる方法は<a href="tips.php#how_to_add_IP">こちら</a><br>';
        $html .= '※拒否IPアドレスを削除する方法は<a href="tips.php#how_to_delete_IP">こちら</a>';
        $html .= '</p>';
      }

    echo $html;
  }

}

  ?>
