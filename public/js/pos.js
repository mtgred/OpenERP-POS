(function() {
  var Pos, Store, db;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  db = openerp.init();
  Store = (function() {
    function Store() {
      var store;
      store = localStorage['pos'];
      this.data = (store && JSON.parse(store)) || {};
    }
    Store.prototype.get = function(key) {
      return this.data[key];
    };
    Store.prototype.set = function(key, value) {
      this.data[key] = value;
      return localStorage['pos'] = JSON.stringify(this.data);
    };
    return Store;
  })();
  Pos = (function() {
    function Pos() {
      this.session.session_login('pos', 'admin', 'admin', __bind(function() {
        this.fetch('pos.category', ['name', 'child_id']);
        return this.fetch('product.product', ['name', 'list_price', 'pos_categ_id', 'taxes_id', 'img']);
      }, this));
    }
    Pos.prototype.session = new db.base.Session('DEBUG');
    Pos.prototype.store = new Store;
    Pos.prototype.fetch = function(osvModel, fields, domain) {
      return this.session.rpc('/base/dataset/search_read', {
        model: osvModel,
        fields: fields,
        domain: domain
      }, __bind(function(result) {
        return this.store.set(osvModel, result['records']);
      }, this));
    };
    return Pos;
  })();
  openerp.point_of_sale = new Pos;
  $(function() {
    $('#steps').buttonset();
    $('#rightpane').width($(window).width() - 445);
    return $(window).resize(function() {
      return $('#rightpane').width($(window).width() - 445);
    });
  });
}).call(this);
