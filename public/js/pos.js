(function() {
  var Pos, Store, db;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
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
        var c, id, _i, _len, _ref, _ref2;
        $.when(this.fetch('pos.category', ['name', 'parent_id', 'child_id']), this.fetch('product.product', ['name', 'list_price', 'pos_categ_id', 'taxes_id', 'img'], [['pos_categ_id', '!=', 'false']])).then(function() {});
        _ref = this.store.get('pos.category');
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          c = _ref[_i];
          this.categories[c.id] = {
            id: c.id,
            name: c.name,
            children: c.child_id,
            parent: c.parent_id[0],
            ancestors: [c.id],
            subtree: [c.id]
          };
        }
        _ref2 = this.categories;
        for (id in _ref2) {
          c = _ref2[id];
          this.current_category = c;
          this.build_ancestors(c.parent);
          this.build_subtree(c);
        }
        this.categories[0] = {
          ancestors: [],
          children: (function() {
            var _j, _len2, _ref3, _results;
            _ref3 = this.store.get('pos.category');
            _results = [];
            for (_j = 0, _len2 = _ref3.length; _j < _len2; _j++) {
              c = _ref3[_j];
              if (!(c.parent_id[0] != null)) {
                _results.push(c.id);
              }
            }
            return _results;
          }).call(this),
          subtree: (function() {
            var _j, _len2, _ref3, _results;
            _ref3 = this.store.get('pos.category');
            _results = [];
            for (_j = 0, _len2 = _ref3.length; _j < _len2; _j++) {
              c = _ref3[_j];
              _results.push(c.id);
            }
            return _results;
          }).call(this)
        };
        return this.ready.resolve();
      }, this));
    }
    Pos.prototype.ready = $.Deferred();
    Pos.prototype.session = new db.base.Session('DEBUG');
    Pos.prototype.store = new Store;
    Pos.prototype.fetch = function(osvModel, fields, domain, cb) {
      cb = cb || __bind(function(result) {
        return this.store.set(osvModel, result['records']);
      }, this);
      return this.session.rpc('/base/dataset/search_read', {
        model: osvModel,
        fields: fields,
        domain: domain
      }, cb);
    };
    Pos.prototype.categories = {};
    Pos.prototype.build_ancestors = function(parent) {
      if (parent != null) {
        this.current_category.ancestors.unshift(parent);
        return this.build_ancestors(this.categories[parent].parent);
      }
    };
    Pos.prototype.build_subtree = function(category) {
      var c, _i, _len, _ref, _results;
      _ref = category.children;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        c = _ref[_i];
        this.current_category.subtree.push(c);
        _results.push(this.build_subtree(this.categories[c]));
      }
      return _results;
    };
    return Pos;
  })();
  window.pos = new Pos;
  $(function() {
    var App;
    $('#steps').buttonset();
    $('#rightpane').width($(window).width() - 445);
    $(window).resize(function() {
      return $('#rightpane').width($(window).width() - 445);
    });
    window.CategoryView = (function() {
      __extends(CategoryView, Backbone.View);
      function CategoryView() {
        CategoryView.__super__.constructor.apply(this, arguments);
      }
      CategoryView.prototype.template = _.template($('#category-template').html());
      CategoryView.prototype.render = function(id) {
        var id;
        return $(this.el).html(this.template({
          breadcrumb: (function() {
            var _i, _len, _ref, _results;
            _ref = pos.categories[id].ancestors;
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              id = _ref[_i];
              _results.push(pos.categories[id]);
            }
            return _results;
          })(),
          categories: (function() {
            var _i, _len, _ref, _results;
            _ref = pos.categories[id].children;
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              id = _ref[_i];
              _results.push(pos.categories[id]);
            }
            return _results;
          })()
        }));
      };
      return CategoryView;
    })();
    App = (function() {
      __extends(App, Backbone.Router);
      function App() {
        App.__super__.constructor.apply(this, arguments);
      }
      App.prototype.routes = {
        '': 'category',
        'category/:id': 'category',
        'payment': 'payment',
        'receipt': 'receipt'
      };
      App.prototype.initialize = function() {
        return this.categoryView = new CategoryView();
      };
      App.prototype.category = function(id) {
        if (id == null) {
          id = 0;
        }
        return $('#rightpane').empty().append(this.categoryView.render(id));
      };
      App.prototype.payment = function() {};
      App.prototype.receipt = function() {};
      return App;
    })();
    return pos.ready.then(function() {
      pos.app = new App;
      return Backbone.history.start();
    });
  });
}).call(this);
