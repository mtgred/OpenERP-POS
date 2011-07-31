db = openerp.init()

class Store
  constructor: ->
    store = localStorage['pos']
    @data = (store && JSON.parse(store)) || {}
  get: (key) -> @data[key]
  set: (key, value) ->
    @data[key] = value
    localStorage['pos'] = JSON.stringify(@data)

class Pos
  constructor: ->
    @session.session_login 'pos', 'admin', 'admin', =>
      $.when(@fetch('pos.category', ['name', 'parent_id', 'child_id']), @fetch('product.product', ['name', 'list_price', 'pos_categ_id', 'taxes_id', 'img'], [['pos_categ_id', '!=', 'false']])).then ->
      for c in @store.get('pos.category')
        @categories[c.id] = id: c.id, name: c.name, children: c.child_id,
        parent: c.parent_id[0], ancestors: [c.id], subtree: [c.id]
      for id, c of @categories
        @current_category = c
        @build_ancestors(c.parent)
        @build_subtree(c)
      @categories[0] =
        ancestors: []
        children: c.id for c in @store.get('pos.category') when not c.parent_id[0]?
        subtree: c.id for c in @store.get('pos.category')
      @ready.resolve()
  ready: $.Deferred()
  session: new db.base.Session('DEBUG')
  store: new Store
  fetch: (osvModel, fields, domain, cb) ->
    cb = cb || (result) => @store.set osvModel, result['records']
    @session.rpc '/base/dataset/search_read',
    model: osvModel, fields: fields, domain: domain, cb
  categories: {}
  build_ancestors: (parent) ->
    if parent?
      @current_category.ancestors.unshift parent
      @build_ancestors(@categories[parent].parent)
  build_subtree: (category) ->
    for c in category.children
      @current_category.subtree.push c
      @build_subtree @categories[c]

window.pos = new Pos

$ ->
  $('#steps').buttonset() # jQuery UI buttonset
  $('#rightpane').width($(window).width() - 445)
  $(window).resize -> $('#rightpane').width($(window).width() - 445)

  #class Product extends Backbone.Model

  #class Products extends Backbone.Collection
    #model: Product
    #collection: pos.store.get('product.product')

  #class ProductView extends Backbone.View
    #template: _.template $('#product-template').html()
    #initialize: ->
    #render: ->

  class window.CategoryView extends Backbone.View
    template: _.template $('#category-template').html()
    render: (id) ->
      $(@el).html @template
        breadcrumb: pos.categories[id] for id in pos.categories[id].ancestors
        categories: pos.categories[id] for id in pos.categories[id].children

  class App extends Backbone.Router
    routes:
      '': 'category'
      'category/:id': 'category'
      'payment': 'payment'
      'receipt': 'receipt'
    initialize: ->
      @categoryView = new CategoryView()
    category: (id = 0) -> $('#rightpane').empty().append(@categoryView.render id)
    payment: ->
    receipt: ->

  pos.ready.then ->
    pos.app = new App
    Backbone.history.start()
