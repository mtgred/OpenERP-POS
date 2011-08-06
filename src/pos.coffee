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
      $.when(
        @fetch('pos.category', ['name','parent_id','child_id']),
        @fetch('product.product', ['name','list_price','pos_categ_id','taxes_id','img'], [['pos_categ_id','!=','false']])
      ).then @build_tree
  ready: $.Deferred()
  session: new db.base.Session('DEBUG')
  store: new Store
  fetch: (osvModel, fields, domain, cb) ->
    cb = cb || (result) => @store.set osvModel, result['records']
    @session.rpc '/base/dataset/search_read', model:osvModel, fields:fields, domain:domain, cb
  categories: {}
  build_tree: =>
    for c in @store.get('pos.category')
      @categories[c.id] = id:c.id, name:c.name, children:c.child_id,
      parent:c.parent_id[0], ancestors:[c.id], subtree:[c.id]
    for id, c of @categories
      @current_category = c
      @build_ancestors(c.parent)
      @build_subtree(c)
    @categories[0] =
      ancestors: []
      children: c.id for c in @store.get('pos.category') when not c.parent_id[0]?
      subtree: c.id for c in @store.get('pos.category')
    @ready.resolve()
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
  $('#rightpane').width($(window).width() - 443)
  $(window).resize -> $('#rightpane').width($(window).width() - 443)

  class ProductView extends Backbone.View
    tagName: 'li'
    className: 'product'
    template: _.template $('#product-template').html()
    render: -> $(@el).html(@template @model.toJSON())
    events: { 'click a': 'addToReceipt' }
    addToReceipt: (e) => e.preventDefault(); pos.order.insert @model

  class ProductListView extends Backbone.View
    tagName: 'ol'
    initialize: -> @collection.bind('reset', @render)
    render: =>
      $(@el).empty()
      @collection.each (product) => $(@el).append (new ProductView model: product).render()
      $('#rightpane').append @el

  class OrderlineView extends Backbone.View
    tagName: 'tr'
    template: _.template $('#orderline-template').html()
    initialize: -> @model.bind('change', @update)
    events: { 'click': 'select' }
    update: => $(@el).hide(); @render()
    render: -> @select(); $(@el).html(@template @model.toJSON()).fadeIn()
    select: ->
      $('tr.selected').removeClass('selected')
      $(@el).addClass 'selected'

  class Orderline extends Backbone.Model
    initialize: -> @set quantity: 1

  class Order extends Backbone.Collection
    insert: (product) ->
      if not @get(product.id)
        @add(new Orderline product.toJSON())
      else
        o = @get(product.id)
        o.set(quantity: (o.get('quantity') + 1))

  class OrderView extends Backbone.View
    tagName: 'tbody'
    initialize: ->
      @collection.bind('add', @addLine)
      @collection.bind('change', @render)
      $('#receipt').append @el
    addLine: (line) => $(@el).append (new OrderlineView model: line).render(); @render()
    render: (e) =>
      total = pos.order.reduce ((sum, x) -> sum + x.get('quantity') * x.get('list_price')), 0
      $('#subtotal').html((total/1.21).toFixed 2).hide().fadeIn()
      $('#tax').html((total/1.21*0.21).toFixed 2).hide().fadeIn()
      $('#total').html(total).hide().fadeIn()

  class CategoryView extends Backbone.View
    template: _.template $('#category-template').html()
    render: (ancestors, children) ->
      $(@el).html @template
        breadcrumb: pos.categories[c] for c in ancestors
        categories: pos.categories[c] for c in children

  class App extends Backbone.Router
    routes:
      '': 'category'
      'category/:id': 'category'
      #'payment': 'payment'
      #'receipt': 'receipt'
    initialize: ->
      @categoryView = new CategoryView
      pos.productList = new Backbone.Collection
      @productListView = new ProductListView(collection: pos.productList)
      pos.order = new Order
      @orderView = new OrderView(collection: pos.order)
    category: (id = 0) ->
      c = pos.categories[id]
      $('#rightpane').empty().prepend(@categoryView.render c.ancestors, c.children)
      pos.productList.reset(p for p in pos.store.get('product.product') when p.pos_categ_id[0] in c.subtree)
    #payment: ->
    #receipt: ->

  pos.ready.then ->
    pos.app = new App
    Backbone.history.start()
