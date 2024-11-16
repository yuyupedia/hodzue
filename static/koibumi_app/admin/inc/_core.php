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

$include = get_included_files();
if (array_shift($include) === __FILE__) {
    die('このファイルへの直接のアクセスは禁止されています。');
}

include_once(dirname(__FILE__).'/_config.php');
include_once(dirname(__FILE__).'/../../koibumi.php');

class koibumi_admin extends koibumi {

  	// コンストラクタ宣言
  	public function __construct() {

  	}

    public function openCSV($day) {

      // 渡ってきた値が日付のみであれば、CSVパスに変換する
      if(preg_match('/^[0-9]{8}$/', $day)) {
        $filename = dirname(__FILE__). '/../../datas/'.$day.'.csv';
      } else {
        $filename = $day;
      }

      // 今日のデータがない場合はfalseを返す
      if (!file_exists($filename)) {
        return false;
      } else {
        // 今日のデータがある場合は、取得した二次元配列から、リクエストの飛んできたページのデータを探す
        $fp = fopen($filename,"r");
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

        // 取得したデータを返す
        return $csvArray;
      }
    }

    private function messageCard($datas, $day) {
      $html = '';
      $cards = array();
      $i = 0;
      foreach($datas as $data) {
        $fav = false;
        $favfilename = dirname(__FILE__). '/../../datas/fav/'.$day.'.csv';
        if (file_exists($favfilename)) {
          $favDatas = $this->openCSV($favfilename);
          $key = in_array($data, $favDatas);
          if($key !== false) {
            $fav = true;
          }
        }
        if(!empty($data[3])) {
          $cards[$data[1]][$data[0]][] = array(
            'message' => $data[4],
            'time' => $data[3],
            'title' => $data[2],
            'num' => $i,
            'fav' => $fav
          );
        }
        $i++;
      }
      foreach($cards as $ip => $card) {
        $html .= '<div class="wrap_message">';
        foreach ($card as $url => $values) {
          foreach ($values as $k => $value) {
            $html .= '<div class="inner_message"><p class="message">'.str_replace( "\n", "<br>", $value['message'] ).'</p>';
            $html .= '<div class="commands"><p class="meta time">'.$value['time'].'</p><form method="post" action="inc/_func.php" class="single" onsubmit="return submitDelete()"><input type="hidden" name="mode" value="delete"><input type="hidden" name="data" value="'.$day.'-'.$value['num'].'"><button type="submit"><span class="material-icons">delete</span></button></form>';
            if($value['fav'] === true) {
              $html .= '<form method="post" action="inc/_func.php" class="single"><input type="hidden" name="mode" value="defav"><input type="hidden" name="data" value="'.$day.'-'.$value['num'].'"><button type="submit"><span class="material-icons favorited">favorite</span></button></form>';
            }
            if($value['fav'] === false) {
              $html .= '<form method="post" action="inc/_func.php" class="single"><input type="hidden" name="mode" value="favorite"><input type="hidden" name="data" value="'.$day.'-'.$value['num'].'"><button type="submit"><span class="material-icons">favorite</span></button></form>';
            }
            $html .= '<label class="label"><input type="checkbox" name="datas[]" value="'.$day.'-'.$value['num'].'" form="archive"><span class="checkbox"></span></label></div></div>';
          }
          $html .= '<p class="meta url"><a href="'.$url.'" target="_blank">送信元：'.$value['title'].'</a></p>';
        } // 送信元URLごとにメッセージを分ける
        $html .= '</div>';
      } // IPごとにカードを分ける
      return $html;
    }

    public function monthlyReport($month) {
      $datas = glob(dirname(__FILE__, 3). '/datas/*.csv');
      $days = array();
      foreach($datas as $data) {
        if (preg_match('{'.$month.'}', $data)) {
          preg_match('/[0-9]{8}/', $data, $day);
          $days[] = $day[0];
        }
      }

      foreach($days as $day) {
        $monthlyReport[$day] = $this->openCSV($day);
      }

      $html = '';

      if (empty($monthlyReport)) {
        $html .= '<p>メッセージはありません。</p>';
      } else{
      krsort($monthlyReport);
        foreach($monthlyReport as $day => $datas) {
          $html .= '<div class="wrap_month">';
          $html .= '<h3>' .date('Y年m月d日',strtotime($day)). '</h3>';
          $html .= $this->messageCard($datas, $day);
          $html .= '</div>';
        }
      }

      return $html;
    }

    public function weeklyReport() {
      define('SEC_PER_DAY', 86400);
      $now = time();
      $days = array();

      for($i=0;$i<7;$i++){
        $days[$i] = date("Ymd", $now - SEC_PER_DAY * $i);
      }

      $weeklyReport = array();

      foreach ($days as $day) {
        if($this->openCSV($day) === false) {
          continue;
        } else {
          $weeklyReport[$day] = $this->openCSV($day);
        }
      }

      $html = '';

      if (empty($weeklyReport)) {
        $html .= '<p>メッセージはありません。</p>';
      } else{
        foreach($weeklyReport as $day => $datas) {
          $html .= '<div class="wrap_month">';
          $html .= '<h3>' .date('Y年m月d日',strtotime($day)). '</h3>';
          $html .= $this->messageCard($datas, $day);
          $html .= '</div>';
        }
      }

      return $html;
    }

    public function dailyReport($day) {
      $datas = array();
      $datas = $this->openCSV($day);
      // return $dailyReport;
      $html = '';

      if (empty($datas)) {
        $html .= '<p>メッセージはありません。</p>';
      } else{
        $html .= '<h3>' .date('Y年m月d日',strtotime($day)). '</h3>';
        $html .= $this->messageCard($datas, $day);
      }

      return $html;
    }

    public function showFav($page) {
      global $showFavCards;
      $favfilenames = glob(dirname(__FILE__, 3). '/datas/fav/*.csv');
      $favDatas = array();
      $Datas = array();

      foreach($favfilenames as $favfilename) {
        if (preg_match('/[0-9]{8}/', $favfilename)) {
          $day = substr($favfilename, -12, 8);
        }
        $favDatas[$day] = $this->openCSV($favfilename);
      }

      if(empty($favDatas)) {
        return '<p>まだお気に入りのメッセージがありません。<br>
        特にうれしかったメッセージはお気に入りに登録して、いつでも見られるようにしましょう！</p>';
      }

      $favData = array();
      $setDays = array();
      foreach($favDatas as $day => $favdata) {
        foreach ($favdata as $data) {
          $filename = dirname(__FILE__, 3). '/datas/'.$day.'.csv';
          $defData = $this->openCSV($filename);
          $key = array_search($data, $defData);
          $data[] = $day;
          $setDays[] = $day;
          $data[] = $key;
          $favData[] = $data;
        }
      }
      array_multisort($setDays, SORT_DESC, $favData);

      $nums = range($showFavCards * ($page-1), $showFavCards * $page - 1);

      $html = '';
      foreach ($nums as $num) {
        if(array_key_exists($num, $favData)) {
          $data = $favData[$num];
          $day = date('Y-m-d', strtotime($data[5]));
          $date = date('Ymd', strtotime($data[5]));

          $html .= '<div class="wrap_message">';
          $html .= '<div class="inner_message"><p class="message">'.str_replace( "\n", "<br>", $data[4] ).'</p>';
          $html .= '<div class="commands"><p class="meta time">'.$day.' '.$data[3].'</p><form method="post" action="inc/_func.php" class="single" onsubmit="return submitDelete()"><input type="hidden" name="mode" value="delete"><input type="hidden" name="data" value="'.$date.'-'.$data[6].'"><button type="submit"><span class="material-icons">delete</span></button></form>';
          $html .= '<form method="post" action="inc/_func.php" class="single"><input type="hidden" name="mode" value="defav"><input type="hidden" name="data" value="'.$date.'-'.$data[6].'"><button type="submit"><span class="material-icons favorited">favorite</span></button></form>';
          $html .= '<label class="label"><input type="checkbox" name="datas[]" value="'.$date.'-'.$data[6].'" form="archive"><span class="checkbox"></span></label></div>';
          $html .= '<p class="meta url"><a href="'.$data[0].'" target="_blank">送信元：'.$data[2].'</a></p>';
          $html .= '</div></div>';
        }
      }

      $nextPage = $page+1;
      $prevPage = $page-1;
      $keys = array_keys($favData);
      $key = array_pop($keys);

      $html .= '<div class="page">';

      if ($page > 1) {
        $html .= '<a href="?page='.$prevPage.'" class="prev"><span class="material-icons">navigate_before</span>前のページ</a><div></div>';
      }
      if ($key > $nums[$showFavCards-1]) {
        $html .= '<div></div><a href="?page='.$nextPage.'" class="next">次のページ<span class="material-icons">navigate_next</span></a>';
      }

      $html .= '</div>';

      return $html;
    }

    public function createMonthlyLists() {
      $datas = glob("../datas/*.csv");
      $dates = array();
      foreach($datas as $data) {
        if (preg_match('/[0-9]{8}/', $data)) {
          $day = preg_replace('/[^0-9]/', '', $data);
          $yyyy = date('Y', strtotime($day));
          $mm = date('m', strtotime($day));
          $dd = date('d', strtotime($day));
          $dates[$yyyy][$mm][] = $dd;
        }
      }
      krsort($dates);
      $dateLists = array();
      foreach($dates as $year => $date) {
        krsort($date);
        $dateLists[$year] = $date;
      }

      $html = '';

      foreach($dateLists as $year => $date) {
        $keys = array_keys($dateLists);
        $key = array_shift($keys);
        // if ($year == array_key_first($dateLists)) {
        if ($year === $key) {
          foreach ($date as $mm => $dd) {
            $html .= '<ul class="list_month">';
            $html .= '<li class="month"><a href="archive.php?month='.$year.''.$mm.'">'.$year.'年'.$mm.'月</a></li>';
            foreach($dd as $d) {
              $html .= '<li><a href="archive.php?day='.$year.''.$mm.''.$d.'">'.$year.'年'.$mm.'月'.$d.'日</a></li>';
            }
            $html .= '</ul>';
          }
        } else {
          $html .= '<ul class="list_year">';
          $html .= '<li class="year"><a>'.$year.'年</a>';
          $html .= '<ul class="list_month child_ul">';
            foreach ($date as $mm => $dd) {
              $html .= '<ul class="list_month">';
              $html .= '<li class="month"><a href="archive.php?month='.$year.''.$mm.'">'.$year.'年'.$mm.'月</a></li>';
              foreach($dd as $d) {
                $html .= '<li><a href="archive.php?day='.$year.''.$mm.''.$d.'">'.$year.'年'.$mm.'月'.$d.'日</a></li>';
              }
              $html .= '</ul>';
            }
          $html .= '</ul>';
          $html .= '</li></ul>';
        }
      }

      return $html;
    }

    public function deleteData($day, $num, $mode, $retData = null) {
      $filename = dirname(__FILE__). '/../../datas/'.$day.'.csv';

      if ($mode === 'default') {
        $arr = $this->openCSV($filename);
        $retData = $arr[$num];
        unset($arr[$num]);

        $fp = fopen($filename, 'w');
        // if( flock($fp, LOCK_SH) ) {

          foreach ($arr as $v) {
            $v[2] = $this->doublequotation($v[2]);
            $v[4] = $this->doublequotation($v[4]);
            $line = implode(',' , $v);
            fwrite($fp, $line . "\n");
          }
          // ファイルを閉じる
        //   flock($fp, LOCK_UN);
        // }
        fclose($fp);

        $d = $this->openCSV($filename);
        if( empty($d) ) {
          unlink($filename);
        }

        return $retData;

      } elseif($mode === 'fav') {

        $favfilename = dirname(__FILE__). '/../../datas/fav/'.$day.'.csv';
        $favarr = $this->openCSV($favfilename);
        if (!empty($favarr)) {
          $key = array_search($retData, $favarr);
          if($key !== false) {
            unset($favarr[$key]);

            $fp = fopen($favfilename, 'w');

            // if( flock( $fp, LOCK_SH) ) {

            foreach ($favarr as $v) {
              $v[2] = $this->doublequotation($v[2]);
              $v[4] = $this->doublequotation($v[4]);
              $line = implode(',' , $v);
              fwrite($fp, $line . "\n");
            }
            // ファイルを閉じる
            //   flock($fp, LOCK_UN);
            // }
            fclose($fp);
          }
        }

        $d = $this->openCSV($favfilename);
        if( empty($d) ) {
          unlink($favfilename);
        }

        return $retData;
      }

    }

    public function showDenyIP() {
      $IPs = file(dirname(__FILE__). '/../../datas/setting/deny.dat', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
      $html = '';
      if( empty($IPs) ) {
        $html .= '<p>現在拒否しているIPアドレスはありません。</p>';
      } else {

        $html .= '<table>';
        foreach($IPs as $IP) {
            $html .= '<tr>';
            $html .= '<th>'.$IP.'</th>';
            $html .= '<td><label>削除<input type="checkbox" name="ips[]" value="'.$IP.'"></label></td>';
            $html .= '</tr>';
        }
        $html .= '</table>';
      }


    return $html;
  }

    public function showNGwords() {
      $words = file(dirname(__FILE__). '/../../datas/setting/NGwords.dat', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
      $html = '';
      if( empty($words) ) {
        $html .= '<p>現在NGワードはありません。</p>';
      } else {

        $html .= '<table style="margin-top:20px;">';
        $html .= '<thead style="background:#e9e9e9;"><tr><th>NGワード</th><th>削除する</th></tr></thead>';
        foreach($words as $word) {
            $html .= '<tr>';
            $html .= '<th>'.$word.'</th>';
            $html .= '<td><label><input type="checkbox" name="words[]" value="'.$word.'"></label></td>';
            $html .= '</tr>';
        }
        $html .= '</table>';
      }


    return $html;
  }
}

  ?>
