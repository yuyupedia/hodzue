
<form method="post" action="inc/_func.php" id="archive" name="archive" onsubmit="return submitArchive()">
  <select name="selection" id="selection">
    <option value="favorite">お気に入りする</option>
    <option value="defav">お気に入り解除</option>
    <option value="delete">削除する</option>
    <option value="deny">このIPアドレスの投稿を拒否する</option>
  </select>
  <button type=”submit” name="action">実行</button>
</form>
