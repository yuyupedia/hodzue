<?php
session_start();
$subtitle = ' | 設定変更';
include_once('inc/_header.php');

$noticeNone = '';
$noticeEvery = '';
$noticeEveryDay = '';
$noticeWeekly = '';
$noticeMonthly = '';
switch ($noticeMail) {
  case 'none':
    $noticeNone = 'checked';
    break;
  case 'every':
    $noticeEvery = 'checked';
    break;
  case 'everyday':
    $noticeEveryDay = 'checked';
    break;
  case 'weekly':
    $noticeWeekly = 'checked';
    break;
  case 'monthly':
    $noticeMonthly = 'checked';
    break;
}
?>

<main>
  <?php include_once('inc/_sidebar.php'); ?>

  <div id="contents">
    <h2>各種設定</h2>
    <form method="post" action="inc/_setting.php" autocomplete="off" onsubmit="return submitSetting()">

      <div class="tab_wrap">
        <input id="tab1" type="radio" name="tab_btn" checked>
        <input id="tab2" type="radio" name="tab_btn">
        <input id="tab3" type="radio" name="tab_btn">

        <div class="tab_area">
          <label class="tab1_label" for="tab1">一般設定</label>
          <label class="tab2_label" for="tab2">メール通知</label>
          <label class="tab3_label" for="tab3">受信拒否</label>
        </div>
        <div class="panel_area">

          <div id="panel1" class="tab_panel">
            <dl>
              <dt>メッセージ文字数上限</dt>
              <dd><input type="number" name="limitMessage" value="<?php echo $limitMessage; ?>"></dd>
            </dl>
            <dl>
              <dt>同一IPによる１日の投稿数上限</dt>
              <dd><input type="number" name="limitPost" value="<?php echo $limitPost; ?>"></dd>
            </dl>
            <dl>
              <dt>お気に入りメッセージのページあたりの表示件数</dt>
              <dd><input type="number" name="showFavCards" value="<?php echo $showFavCards; ?>"></dd>
            </dl>
            <dl>
              <dt>パスワードの変更</dt>
              <dd><label><input type="password" name="newpw" id="newpw" placeholder="新パスワード" autocomplete="new-password"></label><br>
                <label><input type="password" name="newpw-confirm" id="confirm-pw" placeholder="新パスワード（確認用）"></label></dd>
              </dl>
            </div>

            <div id="panel2" class="tab_panel">
              <dl>
                <dt>メール通知</dt>
                <dd id="noticeradio">
                  <label><input type="radio" name="notice" value="none" <?php echo $noticeNone; ?>>通知しない</label><br>
                  <label><input type="radio" name="notice" value="every" <?php echo $noticeEvery; ?>>メッセージを受信するたび通知する</label><br>
                  <label><input type="radio" name="notice" value="everyday" <?php echo $noticeEveryDay; ?>>１日１回通知する <span class="red">*</span></label><br>
                  <label><input type="radio" name="notice" value="weekly" <?php echo $noticeWeekly; ?>>週１回通知する <span class="red">*</span></label><br>
                  <label><input type="radio" name="notice" value="monthly" <?php echo $noticeMonthly; ?>>月１回通知する <span class="red">*</span></label>
                  <p id="notice_memo"><strong><span class="red">*</span>マークのついている通知設定には、cron設定が必要です。</strong>お使いのサーバーの管理画面にログインし、cron設定を行ってください。実行ファイルパスは<code>
                    <?php
                    $url = __FILE__;
                    $url = str_replace('setting.php', '', $url);
                    $url = $url . 'inc/routine.php';
                    echo $url;
                    ?>
                  </code>、cronスケジュールは、コイブミのメール通知設定と同じスケジュール（毎日/毎週/毎月）で設定して下さい。通知するメッセージがない場合はメールを送信しません。
                </p>
              </dd>
            </dl>
            <dl>
              <dt>通知先メールアドレス</dt>
              <dd><input type="email" name="mailaddress" id="mailaddress" value="<?php echo $noticeAddress; ?>"></dd>
            </dl>


          </div>

          <div id="panel3" class="tab_panel">
            <dl>
              <dt>NGワード設定</dt>
              <dd>
                <label><input type="text" name="newNGword" id="newNGword" placeholder="新しいNGワード"></label>
                <?php
                echo $koibumiAdm->showNGwords();
                ?>
              </dd>
            </dl>
            <dl>
              <dt>投稿を受け付けないIP</dt>
              <dd>
                <?php
                echo $koibumiAdm->showDenyIP();
                ?>
              </dd>
            </dl>
          </div>
        </div>
      </div>

      <!-- ここまで -->

      <button type="submit">設定を変更</button>

    </form>
  </div>
</main>

  <?php include_once('inc/_footer.php'); ?>
