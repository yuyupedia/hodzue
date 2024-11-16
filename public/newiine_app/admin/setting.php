<?php
session_start();
$subtitle = '設定変更 | ';
include_once('inc/_header.php');
?>

<main>
  <?php include_once('inc/_sidebar.php'); ?>

  <div id="contents">
    <h2>各種設定</h2>
    <form method="post" action="inc/_setting.php" autocomplete="off" onsubmit="return submitSetting()">

      <div class="tab_wrap">
        <input id="tab1" type="radio" name="tab_btn" checked>
        
        <div class="panel_area">

          <div id="panel1" class="tab_panel">
            <dl>
              <dt>同一IPによる１日のいいね数上限</dt>
              <dd><input type="number" name="limitPost" value="<?php echo $limitPost; ?>"></dd>
            </dl>
            <dl>
              <dt>いいねを拒否するIPアドレス</dt>
              <dd>
                <input type="text" name="banIP" value="" placeholder="12.345.678.90"><br>
                <?php
                  echo $newiineAdm->denyIP();
                ?>
              </dd>
            </dl>
            <dl>
              <dt>管理画面ログインパスワードの変更</dt>
              <dd><label><input type="password" name="newpw" id="newpw" placeholder="新パスワード" autocomplete="new-password"></label><br>
                <label><input type="password" name="newpw-confirm" id="confirm-pw" placeholder="新パスワード（確認用）"></label></dd>
              </dl>
            </div>

        </div>
      </div>

      <button type="submit">設定を変更</button>
      <!-- ※デモなので設定を変更できません。 -->

    </form>
  </div>
</main>

  <?php include_once('inc/_footer.php'); ?>
