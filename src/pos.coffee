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
      @fetch 'pos.category', ['name', 'child_id']
      @fetch 'product.product', ['name', 'list_price', 'pos_categ_id', 'taxes_id', 'img']
  session: new db.base.Session('DEBUG')
  store: new Store
  fetch: (osvModel, fields, domain) ->
    @session.rpc '/base/dataset/search_read',
      model: osvModel, fields: fields, domain: domain, (result) =>
        @store.set osvModel, result['records']

openerp.point_of_sale = new Pos

$ ->
  $('#steps').buttonset() # jQuery UI button set
  $('#rightpane').width($(window).width() - 445)
  $(window).resize -> $('#rightpane').width($(window).width() - 445)
