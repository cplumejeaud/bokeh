toolview = require("./toolview")
ToolView = toolview.ToolView
eventgenerators = require("./eventgenerators")
OnePointWheelEventGenerator = eventgenerators.OnePointWheelEventGenerator
LinearMapper = require("../mappers/1d/linear_mapper").LinearMapper
base = require("../base")
safebind = base.safebind
HasParent = base.HasParent

class ZoomToolView extends ToolView

  initialize : (options) ->
    super(options)
    safebind(this, @model, 'change:dataranges', @build_mappers)
    @build_mappers()

  eventGeneratorClass : OnePointWheelEventGenerator
  evgen_options : {buttonText:"Zoom"}
  tool_events : {
    zoom: "_zoom"}


  build_mappers : () =>
    @mappers = {}
    for temp in _.zip(@mget_obj('dataranges'), @mget('dimensions'))
      [datarange, dim] = temp
      if dim == 'width'
        mapper = new LinearMapper({
          source_range: datarange
          target_range: @plot_view.view_state.get('inner_range_horizontal')
        })
      else
        mapper = new LinearMapper({
          source_range: datarange
          target_range: @plot_view.view_state.get('inner_range_vertical')
        })
      @mappers[dim] = mapper
    return @mappers

  mouse_coords : (e, x, y) ->
    [x_, y_] = [@plot_view.view_state.device_to_sx(x), @plot_view.view_state.device_to_sy(y)]
    return [x_, y_]

  _zoom : (e) ->
    delta = e.delta
    screenX = e.bokehX
    screenY = e.bokehY
    [x, y] = @mouse_coords(e, screenX, screenY)
    speed = @mget('speed')
    factor = - speed  * (delta * 50)

    sx_low = 0
    sx_high = @plot_view.view_state.get('inner_width')
    sy_low = 0
    sy_high = @plot_view.view_state.get('inner_height')

    xstart = @plot_view.xmapper.map_from_target(sx_low-(x-sx_low)*factor)
    xend   = @plot_view.xmapper.map_from_target(sx_high+(sx_high-x)*factor)
    ystart = @plot_view.ymapper.map_from_target(sy_low-(y-sy_low)*factor)
    yend   = @plot_view.ymapper.map_from_target(sy_high+(sy_high-y)*factor)

    @plot_view.x_range.set({start: xstart, end: xend})
    @plot_view.y_range.set({start: ystart, end: yend})


    # for dim, mapper in @mappers
    #   if dim == 'width'
    #     eventpos = x
    #   else
    #     eventpos = y
    #   screenlow = 0
    #   screenhigh = @plot_view.viewstate.get(mapper.screendim)
    #   start = screenlow - (eventpos - screenlow) * factor
    #   end = screenhigh + (screenhigh - eventpos) * factor
    #   [start, end] = [mapper.map_data(start), mapper.map_data(end)]
    #   mapper.data_range.set(
    #     start : start
    #     end : end)
    return null




class ZoomTool extends HasParent
  type : "ZoomTool"
  default_view : ZoomToolView
ZoomTool::defaults = _.clone(ZoomTool::defaults)
_.extend(ZoomTool::defaults
  ,
    dimensions : []
    dataranges : []
    speed : 1/600
)

class ZoomTools extends Backbone.Collection
  model : ZoomTool



exports.ZoomToolView = ZoomToolView
exports.zoomtools = new ZoomTools