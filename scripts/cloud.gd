class_name Cloud
extends Node

## Google accounts and the shared office board.
## Guests stay on this computer. The same Firebase project as N vs Z is used,
## with separate company, roster, and market collections.

signal account_changed
signal board_arrived(rows: Array)
signal market_arrived(rows: Array)
signal claim_arrived(person_id: String, ok: bool, reason: String)
signal sale_arrived(ok: bool, reason: String, info: Dictionary)

const API_KEY := "AIzaSyCyiYPfJ2oS2Dx4UTXzKVmbLgDVUUyHZYk"
const AUTH_DOMAIN := "n-vs-z-saves.firebaseapp.com"
const PROJECT_ID := "n-vs-z-saves"
const APP_ID := "1:594180242834:web:2c03ff1f34f96a4062554b"
const GOOGLE_CLIENT_ID := "594180242834-t0016tou7ua2ds2huboi4alj79lu6irf.apps.googleusercontent.com"

var signed_in := false
var display_name := ""
var email := ""
var last_error := ""

var _status := "boot"
var _uid := ""
var _wait := 0.0
var _seen_notice := ""

const BOOT := """
(function(){
  if (window.__urf) return;
  window.__urf = {status:'boot', uid:'', name:'', email:'', error:'', board:'', market:'', notice:'', gen:0, started:false, want:false, cfg:null, auth:null, db:null, pendingToken:''};
  function clean(s){ return String(s||''); }
  function payloadOf(jwt){
    try {
      var part = jwt.split('.')[1].split('-').join('+').split('_').join('/');
      while (part.length % 4) part += '=';
      return JSON.parse(atob(part));
    } catch (e) { return null; }
  }
  function takeHash(){
    var hash = window.location.hash || '';
    if (hash.indexOf('id_token=') < 0) return;
    var params = new URLSearchParams(hash.substring(1));
    var idToken = params.get('id_token') || '';
    history.replaceState(null, '', window.location.pathname + window.location.search);
    if (!idToken) return;
    var body = payloadOf(idToken);
    var nonce = '';
    try { nonce = sessionStorage.getItem('urf_nonce') || ''; } catch (e2) {}
    try { sessionStorage.removeItem('urf_nonce'); } catch (e3) {}
    if (!body || (nonce && body.nonce && body.nonce !== nonce)) {
      window.__urf.error = 'Google sign-in did not finish.';
      return;
    }
    window.__urf.pendingToken = idToken;
  }
  takeHash();
  window.urfState = function(){
    var a = window.__urf;
    var board = a.board || '';
    var market = a.market || '';
    var notice = a.notice || '';
    a.board = '';
    a.market = '';
    a.notice = '';
    return JSON.stringify({gen:a.gen, status:a.status, uid:a.uid, name:a.name, email:a.email, error:a.error, board:board, market:market, notice:notice});
  };
  function loadScript(src, next, fail){
    var tag = document.createElement('script');
    tag.src = src; tag.onload = next; tag.onerror = fail;
    document.head.appendChild(tag);
  }
  var srcs = [
    'https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js',
    'https://www.gstatic.com/firebasejs/10.14.1/firebase-auth-compat.js',
    'https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore-compat.js'
  ];
  function loadAt(i){
    if (i >= srcs.length) { window.urfTry(); return; }
    loadScript(srcs[i], function(){ loadAt(i+1); }, function(){
      window.__urf.status = 'error';
      window.__urf.error = 'Could not reach Google.';
    });
  }
  window.urfStart = function(cfg){
    window.__urf.cfg = cfg;
    window.__urf.want = true;
    if (typeof firebase !== 'undefined' && firebase.firestore) window.urfTry();
    else loadAt(0);
  };
  window.urfTry = function(){
    var a = window.__urf;
    if (!a.want || a.started) return;
    if (typeof firebase === 'undefined' || !firebase.auth || !firebase.firestore) return;
    a.started = true;
    try {
      firebase.initializeApp(a.cfg);
      a.auth = firebase.auth();
      a.db = firebase.firestore();
      a.auth.setPersistence(firebase.auth.Auth.Persistence.LOCAL).catch(function(){});
      if (a.pendingToken) {
        var token = a.pendingToken;
        a.pendingToken = '';
        a.auth.signInWithCredential(firebase.auth.GoogleAuthProvider.credential(token)).catch(function(){
          a.error = 'Google sign-in did not finish.';
        });
      }
      a.auth.onAuthStateChanged(function(user){
        if (user) {
          a.status = 'signed';
          a.uid = user.uid;
          a.name = user.displayName || user.email || 'Google';
          a.email = user.email || '';
          a.error = '';
        } else {
          a.status = 'guest';
          a.uid = '';
          a.name = '';
          a.email = '';
        }
        a.gen += 1;
      });
    } catch (e) {
      a.status = 'error';
      a.error = 'Google sign-in is not ready.';
    }
  };
  function startRedirect(){
    var a = window.__urf;
    var clientId = a.cfg && a.cfg.clientId ? a.cfg.clientId : '';
    if (!clientId) { a.error = 'Google sign-in is not ready.'; return; }
    var nonce = Math.random().toString(36).slice(2) + Date.now().toString(36);
    try { sessionStorage.setItem('urf_nonce', nonce); } catch (e4) {}
    var back = location.origin + location.pathname;
    location.assign('https://accounts.google.com/o/oauth2/v2/auth?client_id=' + encodeURIComponent(clientId)
      + '&redirect_uri=' + encodeURIComponent(back)
      + '&response_type=id_token&scope=' + encodeURIComponent('openid email profile')
      + '&nonce=' + encodeURIComponent(nonce)
      + '&prompt=select_account&state=urf');
  }
  window.urfSignIn = function(){
    var a = window.__urf;
    if (!a.auth) { a.error = 'Still connecting. Try again in a moment.'; return; }
    var provider = new firebase.auth.GoogleAuthProvider();
    provider.setCustomParameters({prompt:'select_account'});
    a.auth.signInWithPopup(provider).catch(function(err){
      var code = err && err.code ? err.code : '';
      if (code === 'auth/popup-closed-by-user' || code === 'auth/cancelled-popup-request') return;
      startRedirect();
    });
  };
  window.urfSignOut = function(){
    var a = window.__urf;
    if (a.auth) a.auth.signOut().catch(function(){ a.error = 'Could not sign out.'; });
  };
  function note(obj){ var a = window.__urf; a.notice = JSON.stringify(obj); a.gen += 1; }
  window.urfClaim = function(person, name, ability){
    var a = window.__urf;
    if (!a.auth || !a.auth.currentUser) { note({kind:'claim', id:person, ok:false, reason:'Sign in first.'}); return; }
    var ref = a.db.collection('urf_roster').doc(person);
    a.db.runTransaction(function(tx){
      return tx.get(ref).then(function(doc){
        var holder = doc.exists && doc.data().holder ? doc.data().holder : '';
        if (holder && holder !== a.auth.currentUser.uid) throw new Error('taken');
        tx.set(ref, {name:name, ability:ability, holder:a.auth.currentUser.uid}, {merge:true});
      });
    }).then(function(){ note({kind:'claim', id:person, ok:true, reason:''}); })
      .catch(function(){ note({kind:'claim', id:person, ok:false, reason:'Someone else already hired them.'}); });
  };
  window.urfRelease = function(person){
    var a = window.__urf;
    if (!a.auth || !a.auth.currentUser) return;
    var ref = a.db.collection('urf_roster').doc(person);
    ref.get().then(function(doc){
      if (!doc.exists || doc.data().holder !== a.auth.currentUser.uid) return;
      return ref.set({holder:''}, {merge:true});
    }).catch(function(){});
  };
  window.urfPushCompany = function(data){
    var a = window.__urf;
    if (!a.auth || !a.auth.currentUser || !data) return;
    a.db.collection('urf_companies').doc(a.auth.currentUser.uid).set({
      name: String(data.name||'Company').slice(0, 24),
      profit: Math.round(Number(data.profit)||0),
      capital: Math.round(Number(data.capital)||0),
      workers: Math.max(0, Math.min(4, Math.round(Number(data.workers)||0))),
      best_worker: String(data.best_worker||'').slice(0, 24),
      best_output: Math.max(0, Math.round(Number(data.best_output)||0)),
      updated: firebase.firestore.FieldValue.serverTimestamp()
    }).catch(function(){ a.error = 'Could not publish the company.'; a.gen += 1; });
  };
  window.urfLoadBoard = function(){
    var a = window.__urf;
    if (!a.db) { a.error = 'Still connecting.'; a.gen += 1; return; }
    a.db.collection('urf_companies').get().then(function(snap){
      var rows = [];
      snap.forEach(function(doc){
        var d = doc.data() || {};
        rows.push({uid:doc.id, name:String(d.name||''), profit:Number(d.profit)||0, capital:Number(d.capital)||0, workers:Number(d.workers)||0, best_worker:String(d.best_worker||''), best_output:Number(d.best_output)||0});
      });
      a.board = JSON.stringify(rows);
      a.gen += 1;
    }).catch(function(){ a.error = 'Could not load the ranking.'; a.gen += 1; });
  };
  window.urfList = function(person, name, ability, price){
    var a = window.__urf;
    if (!a.auth || !a.auth.currentUser) { note({kind:'sale', ok:false, reason:'Sign in first.'}); return; }
    var id = a.auth.currentUser.uid + '_' + person;
    a.db.collection('urf_market').doc(id).set({
      seller: a.auth.currentUser.uid, person: person, name: name, ability: ability,
      price: Math.max(1, Math.round(Number(price)||0)), buyer: ''
    }).then(function(){ note({kind:'sale', ok:true, reason:'Listed ' + name + '.', id:id}); })
      .catch(function(){ note({kind:'sale', ok:false, reason:'Could not publish the listing.'}); });
  };
  window.urfLoadMarket = function(){
    var a = window.__urf;
    if (!a.db) return;
    a.db.collection('urf_market').get().then(function(snap){
      var openRows = [];
      var soldRows = [];
      snap.forEach(function(doc){
        var d = doc.data() || {};
        var row = {id:doc.id, seller:String(d.seller||''), person:String(d.person||''), name:String(d.name||''), ability:String(d.ability||''), price:Number(d.price)||0};
        var me = a.auth && a.auth.currentUser ? a.auth.currentUser.uid : '';
        if (d.buyer && d.seller === me && !d.paid) {
          soldRows.push(row);
          doc.ref.set({paid:true}, {merge:true}).catch(function(){});
        } else if (!d.buyer) {
          openRows.push(row);
        }
      });
      a.market = JSON.stringify({open: openRows, sold: soldRows});
      a.gen += 1;
    }).catch(function(){ a.error = 'Could not load the market.'; a.gen += 1; });
  };
  window.urfBuy = function(listingId){
    var a = window.__urf;
    if (!a.auth || !a.auth.currentUser) { note({kind:'buy', ok:false, reason:'Sign in first.'}); return; }
    var ref = a.db.collection('urf_market').doc(listingId);
    ref.get().then(function(doc){
      if (!doc.exists) { note({kind:'buy', ok:false, reason:'That listing is gone.'}); return; }
      var d = doc.data() || {};
      if (d.buyer) { note({kind:'buy', ok:false, reason:'Someone else already agreed.'}); return; }
      if (d.seller === a.auth.currentUser.uid) { note({kind:'buy', ok:false, reason:'That person already works for you.'}); return; }
      return ref.update({buyer: a.auth.currentUser.uid}).then(function(){
        return a.db.collection('urf_roster').doc(d.person).set({holder: a.auth.currentUser.uid, name:d.name, ability:d.ability}, {merge:true});
      }).then(function(){
        note({kind:'buy', ok:true, reason:'', person:d.person, name:d.name, price:d.price, ability:d.ability});
      });
    }).catch(function(){ note({kind:'buy', ok:false, reason:'The transfer did not finish.'}); });
  };
})();
"""


func _ready() -> void:
	if not OS.has_feature("web"):
		set_process(false)
		return
	JavaScriptBridge.eval(BOOT, true)
	var cfg := JSON.stringify({
		"apiKey": API_KEY,
		"authDomain": AUTH_DOMAIN,
		"projectId": PROJECT_ID,
		"appId": APP_ID,
		"clientId": GOOGLE_CLIENT_ID,
	})
	JavaScriptBridge.eval("urfStart(" + cfg + ")", true)


func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = 0.3
	_poll()


func sign_in() -> void:
	if not OS.has_feature("web"):
		last_error = "Google sign-in is on the website version."
		account_changed.emit()
		return
	JavaScriptBridge.eval("urfSignIn()", true)


func sign_out() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("urfSignOut()", true)


func claim(person_id: String, person_name: String, ability: String) -> void:
	if not OS.has_feature("web") or not signed_in:
		claim_arrived.emit(person_id, true, "")
		return
	var payload := JSON.stringify({"id": person_id, "name": person_name, "ability": ability})
	JavaScriptBridge.eval("urfClaim(%s, %s, %s)" % [_js(person_id), _js(person_name), _js(ability)], true)
	payload = payload


func release(person_id: String) -> void:
	if OS.has_feature("web") and signed_in:
		JavaScriptBridge.eval("urfRelease(%s)" % _js(person_id), true)


func push_company(data: Dictionary) -> void:
	if OS.has_feature("web") and signed_in:
		JavaScriptBridge.eval("urfPushCompany(" + JSON.stringify(data) + ")", true)


func load_board() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("urfLoadBoard()", true)


func load_market() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("urfLoadMarket()", true)


func list_sale(person_id: String, person_name: String, ability: String, price: int) -> void:
	if not signed_in:
		sale_arrived.emit(false, "Sign in with Google to sell a person to another company.", {})
		return
	JavaScriptBridge.eval("urfList(%s, %s, %s, %d)" % [_js(person_id), _js(person_name), _js(ability), price], true)


func buy(listing_id: String) -> void:
	if not signed_in:
		sale_arrived.emit(false, "Sign in with Google to agree a transfer.", {})
		return
	JavaScriptBridge.eval("urfBuy(%s)" % _js(listing_id), true)


func _js(text: String) -> String:
	return JSON.stringify(text)


func _poll() -> void:
	var raw: Variant = JavaScriptBridge.eval("urfState()", true)
	var text := str(raw)
	if text == "" or text == "null":
		return
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return
	var packet: Dictionary = parsed
	var status := str(packet.get("status", ""))
	var uid := str(packet.get("uid", ""))
	var err := str(packet.get("error", ""))
	var changed := status != _status or uid != _uid or err != last_error
	_status = status
	_uid = uid
	display_name = str(packet.get("name", ""))
	email = str(packet.get("email", ""))
	last_error = err
	signed_in = status == "signed" and uid != ""
	if changed:
		account_changed.emit()
	var board_text := str(packet.get("board", ""))
	if board_text != "":
		var rows: Variant = JSON.parse_string(board_text)
		if rows is Array:
			board_arrived.emit(rows)
	var market_text := str(packet.get("market", ""))
	if market_text != "":
		var listed: Variant = JSON.parse_string(market_text)
		if listed is Dictionary:
			var open_rows: Variant = listed.get("open", [])
			if open_rows is Array:
				market_arrived.emit(open_rows)
			var sold_rows: Variant = listed.get("sold", [])
			if sold_rows is Array:
				for sold in sold_rows:
					if sold is Dictionary:
						sale_arrived.emit(true, "", sold)
	var notice_text := str(packet.get("notice", ""))
	if notice_text != "" and notice_text != _seen_notice:
		_seen_notice = notice_text
		var notice: Variant = JSON.parse_string(notice_text)
		if notice is Dictionary:
			_take_notice(notice)


func _take_notice(notice: Dictionary) -> void:
	var kind := str(notice.get("kind", ""))
	if kind == "claim":
		claim_arrived.emit(str(notice.get("id", "")), bool(notice.get("ok", false)), str(notice.get("reason", "")))
	elif kind == "sale" or kind == "buy":
		sale_arrived.emit(bool(notice.get("ok", false)), str(notice.get("reason", "")), notice)
