module SuperCat
  module ContantLib

    module DictConstant
      ATTR_DICT_SC_MAT ||= "SC material"
      ATTR_DICT_SC_MAT_OLD ||= "rzw_prototool_house3d_gen"
      ATTR_DICT_SC_ASSIST ||= "SC assist"
      ATTR_DICT_ABSTRACTION ||= "SC_abstraction"
      A ||= "SC_"
    end

    module MaterialConstant
      CV_MAT_STONE ||= "V-Rockery"
      CV_MAT_SOIL ||= "V-Grassland"
      CV_MAT_TREE ||= "V-Tree"
      CV_MAT_WATER ||= "V-Water"
      CV_MAT_ROAD ||= "V-Road"
      CV_MAT_SUNSHADE ||= "V-Sunshade"
      CV_MAT_GROUND ||= "M01 100mm brick (Grey)"
      CV_NON_BUILDING ||= [CV_MAT_STONE,CV_MAT_SOIL,CV_MAT_TREE,CV_MAT_WATER,CV_MAT_SUNSHADE,CV_MAT_SUNSHADE]
    end

    module PathConstant
      LIB_ROOT ||= RZWLIB2::PLUGIN_ROOT
      LIB_ID ||= RZWLIB2::PLUGIN_ID
      LIB_DIR = RZWLIB2::PLUGIN_DIR
      PATH_DATABASE_REAL_MATERIAL ||= File.join(LIB_DIR, "res", "data", "material_database.json")
    end

    module TextConstant
      CV_DEFAULT = "Default"
      CV_LESS_THAN_3_POINTS = "Less than 3 points, unable to form a closed curve."
    end

    module ValConstant
      STD_WIND ||= "Wind Speed [m/s]"
      STD_WIND_X ||= "Velocity X [m/s]"
      STD_GEO ||= "Geo"
      WIND ||= 'Wind'
      MRT ||= 'MRT'
      STD_MRT ||= 'Mean Radiant Temperature [℃]'
      STD_COMFACOURTYARD ||= "COMFA courtyard [W/m2]"
      STD_UTCI ||= "UTCI [℃]"
      UTCI ||= "UTCI"
      COMFAcourtyard ||= "COMFAcourtyard"
      OTC_L ||= [UTCI,COMFAcourtyard]
    end


    module KeyConstant
      CK_TYPE ||= "type"
      CK_STRC ||= "structure"
      CK_HOUSE_MAT ||= "material"
      CK_TYPE2 ||= "type"
      CK_STRC2 ||= "strc"
      CK_HOUSE_MAT2 ||= "material"
      CK_NAME ||= 'name'
      CK_CPT ||= 'cpt'
      CK_TRANSMIT ||= 'transmit'
      CK_MODE ||= 'mode'
      CK_GROUP ||= 'group'
      CK_ID_FACE_ANALYSIS ||= 'id'
      CK_VAL ||= "v"
      CK_IS_EXIST ||= 'Is Exist'
    end

    module KeyMatThermalConstant
      CK_INDEX ||= 'index'
      CK_SCIENTIFIC_NAME ||= 'scientific_name'
      CK_THICKNESS_DEFAULT ||= 'thickness_default'
      CK_THERMAL_CONDUCTIVITY ||= 'thermal_conductivity'
      CK_SPECIFIC_HEAT ||= 'specific_heat'
      CK_DENSITY ||= 'density'
      CK_SOLVING_MODEL ||= 'solving_model'
      CK_SOLAR_ABSORPTANCE ||= 'solar_absorptance'
      CK_THERMAL_ABSORPTANCE ||= 'thermal_absorptance'
      CK_CHINESE_NAME ||= 'chinese_name'
      CK_COLOR ||= 'color'
      CK_LIST_RM ||= [CK_INDEX, CK_CHINESE_NAME,
                      CK_THICKNESS_DEFAULT, CK_THERMAL_CONDUCTIVITY, CK_SPECIFIC_HEAT,
                      CK_DENSITY, CK_SOLAR_ABSORPTANCE, CK_THERMAL_ABSORPTANCE,
                      CK_SOLVING_MODEL,CK_COLOR]
    end

    module PathTextureConstant
      PATH_TEXTURE ||= File.join(RZWLIB2::PLUGIN_DIR, "res", "data", "texture")
      TEXTURE_DEFAULT ||= File.join(PATH_TEXTURE, "default.png")
      TEXTURE_TREE ||= File.join(PATH_TEXTURE, "V-Tree.png")
      TEXTURE_ROCKERY ||= File.join(PATH_TEXTURE, "V-Rockery.png")
      TEXTURE_WATER ||= File.join(PATH_TEXTURE, "V-Water.png")
      TEXTURE_ROAD ||= File.join(PATH_TEXTURE, "V-Road.png")
      TEXTURE_GRASSLAND ||= File.join(PATH_TEXTURE, "V-Grassland.png")
      TEXTURE_PATCH ||= File.join(PATH_TEXTURE, "V-Patch.png")
      TEXTURE_HOUSE3D_OUTTER ||= File.join(PATH_TEXTURE, "Brickwork (Standard).png")
      TEXTURE_ROOF_SLOPE ||= File.join(PATH_TEXTURE, "Brickwork (Roof).png") # Sketchup::Color.new 48, 46, 46, 250 #灰色
      TEXTURE_FLOOR_TOP ||= File.join(PATH_TEXTURE, "M01 100mm brick (Grey).png")
      TEXTURE_ROOF_GABLE ||= File.join(PATH_TEXTURE, "Concrete Block (Heavyweight).png")
    end

    module Key3DConstant
      CK_HOUSE_OPENING_DEG ||= 'House openness degree'
      CK_HOUSE_FLOOR_NUM ||= 'Number of house floors'
      CK_HOUSE_FLOORS_HEIGHT ||= 'Floor height'
      CK_HOUSE_WINDOW_TYPE ||= 'House window type'
      CK_HOUSE_WINDOW_SCAL ||= 'House window scale'
      CK_HOUSE_DOOR_TYPE ||= "House door type"
      CK_HOUSE_DOOR_SCALE ||= "House door scale"
      CK_HOUSE_ROOF_TYPE ||= 'House roof type'
      CK_TREE_CTRL ||= 'Tree control information'
      CK_SHRUB_CTRL ||= 'Shrub control information'
      CK_TREE_SIZE ||= 'Tree size information'
      CK_TREE_NOTE ||= 'Tree annotation information'
      CK_TREE_SIDES ||= 'Number of tree sides'
      CK_TREE_INFO_BASE ||= 'info_base_tree'
    end

    module ParamConstant
      CK_RADIUS ||= "radius" # STRINGS.GetString("radius")
      CK_CENTER ||= "center" # STRINGS.GetString("center")
      CK_SEF ||= "SEF" # STRINGS.GetString("SEF")
      CK_TEF ||= "TEF" # STRINGS.GetString("SEF")
      CK_SVF ||= "SVF" # STRINGS.GetString("SVF")
      CK_DOME ||= "DOME" # STRINGS.GetString("SVF")
      CK_CIRCLE ||= "CIRCLE" # STRINGS.GetString("SVF")
      CK_NONE ||= "NONE" # STRINGS.GetString("SVF")
      CK_ALL ||= "ALL" # STRINGS.GetString("SVF")
      CK_KCLUSTER ||= "K"
      CK_NUM ||= 'num'
      CK_ABS_RADIUS ||= "radius"
    end

    module ColorNameConstant
      COLOR_LAYOUT_AXES_NAME ||= 'layout_axes_color'
      COLOR_REDLINE_NAME ||= 'redline_color'
      COLOR_LAYOUT_ENTRANCE_NAME ||= 'layout_entrance_color'
      COLOR_HOUSE_ENTRANCE_NAME1 ||= 'house_entrance_color_front'
      COLOR_HOUSE_ENTRANCE_NAME2 ||= 'house_entrance_color_back'
      COLOR_HOUSE_NAME ||= 'house_color'
      COLOR_HOUSE_INNER_NAME ||= 'house_inner_color'
      COLOR_HOUSE_OUTTER_NAME ||= 'house_outter_color'
      COLOR_HOUSE_ROOF_SLOPE_NAME ||= 'house_roof_slope_color'
      COLOR_HOUSE_FLOOR_TOP_NAME ||= 'house_floor_top_color'
      COLOR_HOUSE_ROOF_GABLE_NAME ||= 'house_roof_gable_color'
      COLOR_HOUSE_FREE_NAME ||= 'house_free_color'
      COLOR_TREE_NAME ||= 'tree_color'
      TEXTURE_ROKCERY_NAME ||= 'rockery_color'
      COLOR_PATCH_NAME ||= 'patch_color'
      COLOR_WATER_NAME ||= 'water_color'
      COLOR_LAYOUT_NAME ||= 'layout_color'
      COLOR_BACK_DEFAULT_NAME ||= 'back_default'
      COLOR_LAYOUT_VIEWPOINT_FROM_HEN_NAME ||= 'layout_viewpt_from_house_en_color'
      COLOR_LAYOUT_VIEWPOINT_FROM_CO_NAME ||= 'layout_viewpt_from_corridor_color'
      COLOR_LAYOUT_VIEWPOINT_FROM_HCO_NAME ||= 'layout_viewpt_from_house_co_color'
      COLOR_GRASSLAND_NAME ||= 'grassland_color'
      COLOR_PATCH_NAME ||= 'patch_color'
      COLOR_SHRUB_NAME ||= 'shrub_color'
      COLOR_ROCKERY_NAME ||= 'rockery_color'
      COLOR_MEASURE_PT_NAME ||= 'measure_pt_color'
      COLOR_CORRIDOR_NAME ||= 'corridor_color'
      COLOR_ROAD_NAME ||= 'road_color'
      COLOR_HCORRIDOR_NAME ||= 'house_corridor_color'
      COLOR_WALL_NAME ||= 'wall_color'
      COLOR_GROUND_NAME ||= 'ground_color'
      COLOR_BRIDGE_NAME ||= 'bridge_color'
      COLOR_SUNSHADE_BOARD_NAME ||= 'sunshade_board'
    end

    module ColorConstant
      OPT_PREVIEW_COLOR ||= Sketchup::Color.new 20, 20, 20, 250 #灰色
      OPT_SELECTED_COLOR ||= Sketchup::Color.new 255, 0, 0, 250 #黄色
      OPT_PTBASE_SELECTED_COLOR ||= Sketchup::Color.new 255, 255, 0, 250 #黄色
      OPT_PTBASE_RECORD_COLOR ||= Sketchup::Color.new 255, 0, 0, 250 #红色

      COLOR_LAYOUT ||= 'pink'
      COLOR_BACK_DEFAULT ||= 'white'
      COLOR_LAYOUT_VIEWPOINT_FROM_HEN ||= 'red'
      COLOR_LAYOUT_VIEWPOINT_FROM_CO ||= 'orange'
      COLOR_LAYOUT_VIEWPOINT_FROM_HCO ||= 'salmon'
      COLOR_GRASSLAND ||= 'GreenYellow'
      COLOR_PATCH ||= 'silver'
      COLOR_SHRUB ||= 'Green'
      COLOR_ROCKERY ||= 'IndianRed'
      COLOR_MEASURE_PT ||= 'red'
      COLOR_CORRIDOR ||= 'orange'
      COLOR_ROAD  ||= 'gray'
      COLOR_WALL_HIGH ||= 'BurlyWood'
      COLOR_WALL_LOW ||= 'DarkSalmon'
      COLOR_BRIDGE_HIGH ||= 'CornflowerBlue'
      COLOR_BRIDGE_LOW ||= 'LavenderBlush'
      COLOR_HCORRIDOR ||= 'orange'
      COLOR_POLYGON_CIRCLE ||= 'blue'
      COLOR_TRANSPAREN ||= 'blue'
      COLOR_WATER ||= 'cyan'
      COLOR_TREE ||= 'ForestGreen'
      COLOR_LAYOUT_AXES ||= 'red'
      COLOR_LAYOUT_ENTRANCE ||= 'red'
      COLOR_SUNSHADE_BOARD ||= 'cyan'
      COLOR_HOUSE3D_INNER ||= COLOR_HOUSE ||= 'pink' # Sketchup::Color.new 219, 218, 193, 57
      COLOR_HOUSE3D_OUTTER ||= COLOR_HOUSE_FREE ||= 'LightSalmon'
    end

    module GeomConstant
      CK_SEF_DOME ||= 'SEF_DOME'
      CK_SEF_PLANE ||= 'SEF_PLANE'
      CK_SVF_CIRCLE ||= 'SVF_CIRCLE'
      CK_CHESSBOARD ||= 'CHESSBOARD'
      CK_LEGEND ||= 'Legend'
      CK_PTBASE ||= 'PtBase'
    end

    module TypeConstant
      CV_HOUSE_STRC ||= 'House Strc'
      CV_GROUND ||= 'Ground'
      CV_TREE ||= 'Tree'
      CV_SOURCE ||= 'Source'
      CV_WATER ||= 'Water'
      CV_GRASSLAND ||= 'Grassland'
      CV_PATCH ||= 'Patch'
      CV_SHRUB ||= 'Shrub'
      CV_ROCKERY ||= 'Rockery'
      CV_SUNSHADE_BOARD ||= 'SunshadeBoard'
      CV_BUILDING ||= 'Building'
      CV_HOUSE ||= 'House'
      CV_CO ||= 'Corridor'
      CV_CORRIDOR ||= 'Corridor'
      CV_ROAD ||= 'Road'
      CV_WALL ||= 'Wall'
      CV_BRIDGE ||= 'Bridge'
      CV_HCORRIDOR ||= 'HouseCorridor'
      CV_HENTRANCE ||= 'HouseEntrance'
      CV_REDLINE ||= 'Redline'
      CV_MEASURE_PT ||= 'MeasurePoint'

      CV_TVF ||= 'TVF'
      CV_BVF ||= 'BVF'
      CV_VF_DICT = {
        TypeConstant::CV_TREE => TypeConstant::CV_TVF,
        TypeConstant::CV_HOUSE => TypeConstant::CV_BVF
      }

      ALL_HAVE_OUT_SURFACE_TYPE ||= [CV_HOUSE_STRC, CV_WATER, CV_GRASSLAND, CV_ROCKERY, CV_HOUSE,CV_REDLINE]
      NON_BUILDING_TYPE = [CV_CORRIDOR,CV_ROAD,CV_TREE,CV_BRIDGE, CV_WATER, CV_GRASSLAND, CV_SHRUB, CV_ROCKERY, CV_PATCH, CV_SUNSHADE_BOARD]

      CV_HOUSE3D ||= 'House3d'
      CV_VIEWPORT_PREFIX ||= 'Viewport_'
      CV_VIEWPOINT_PREFIX ||= 'Viewpoint_'
      CV_VIEWPORT_FRAME ||= 'VP_Frame'

      CV_REDLINE_CLINE ||= 'Redline_Cline'
      CV_LAYOUT_AXES ||= 'Axes'
      CV_LAYOUT_ENTRANCE ||= 'Entrance'
      CV_LAYOUT ||= 'Layout'
      CV_VIEWPORT ||= 'Viewport'
      CV_VP_GEN_LAYOUT ||= 'LayoutGen'
      CV_VP_GEN_VORONOI ||= 'VoronoiGen'

      CV_LAYOUT_AXES ||= 'Axes'
      CV_LAYOUT_ENTRANCE ||= 'Entrance'
      CV_LAYOUT ||= 'Layout'
      CV_SIGNATURE ||= 'Signature'
      CV_MEASURE_PT ||= 'MeasurePoint'
      CV_MEASURE_PT_3D ||= '3D Measure Point'

      ALL_LAND_TYPE ||= [CV_HOUSE, CV_WATER, CV_GRASSLAND, CV_CORRIDOR, CV_ROAD, CV_PATCH]
      ALL_TYPE ||= [CV_REDLINE, CV_LAYOUT_AXES, CV_LAYOUT_ENTRANCE, CV_HOUSE, CV_WATER, CV_GRASSLAND, CV_CORRIDOR, CV_HCORRIDOR, CV_ROAD, CV_PATCH]
      ALL_VP_TYPE ||= [CV_VIEWPORT, CV_VP_GEN_LAYOUT, CV_VP_GEN_VORONOI]
    end

    module StructConstant

      CV_HOUSE_STRC ||= 'House Strc'
      CV_CO_STRC ||= 'Corridor Strc'
      CV_RO_STRC ||= 'Road Strc'
      CV_WL_STRC ||= 'Wall Strc'
      CV_WT_STRC ||= 'Water Strc'
      CV_RK_STRC ||= 'Rockery Strc'
      CV_GR_STRC ||= 'Grassland Strc'
      CV_PH_STRC ||= 'Patch Strc'
      CV_RL_STRC ||= 'Redline Strc'
      CV_BR_STRC ||= 'Bridge Strc'
      CVA_HOUSEX_WALL ||= 'House Wall'
      CVA_HOUSEX_WALLINNER ||= 'Inner Wall'
      CVA_HOUSEX_WALLDOOR ||= 'Door Wall'
      CVA_HOUSEX_WALLWIN ||= 'Window Wall'
      CVA_HOUSEX_STAIRWELL ||= 'Stair Well'
      CVA_TOP ||= 'Top'

      CVA_HOUSEX_WALLOUTER ||= 'Outter Wall'
      CVA_ROOFGABLE ||= 'Roof Gable'
      CVA_ROOFSLOPE ||= 'Roof Slope'
      CVA_ROOFSOFFIT_OUTTER ||= 'Roof Soffit Outter'
      CVA_HOUSEX_FLOOR ||= 'Floor Top'
      CVA_WATER_TOP ||= 'Water_Top'
      CVA_GRASSLAND_TOP ||= 'Grassland_Top'
      CVA_ROCKERY_TOP ||= 'Rockery_Top'

      CVA_HOUSEX_WALLINNER ||= 'Inner Wall'
      CVA_HOUSEX_WALLOUTER ||= 'Outter Wall'
      CVA_HOUSEX_FLOOR ||= 'Floor Top'
      CVA_HOUSEX_WALLDOOR ||= 'Door Wall'
      CVA_HOUSEX_WALLWIN ||= 'Window Wall'
      CVA_HOUSEX_STAIRWELL ||= 'Stair Well'
      CVA_WATER_TOP ||= 'Water_Top'
      CVA_GRASSLAND_TOP ||= 'Grassland_Top'
      CVA_ROCKERY_TOP ||= 'Rockery_Top'
      CVA_TOP ||= 'Top'

      CVA_CORRIDOR_SIDES ||= 'Corridor sides'
      CVA_BRIDGE_SIDES ||= 'Bridge sides'
      CVA_BRIDGE_FLOOR ||= 'Bridge floor'
      CVA_ROOFGABLE ||= 'Roof Gable'
      CVA_ROOFSLOPE ||= 'Roof Slope'
      CVA_ROOFSOFFIT_OUTTER ||= 'Roof Soffit Outter'
      CVA_ROOFSOFFIT_INNER ||= 'Roof Soffit Inner'

      CV_EDGE4FENCH_INNER ||= 'edge4wall_rl_inner'
      CV_EDGE4FENCH_OUTER ||= 'edge4wall_rl_outer'
      CV_FENCH_INNER ||= 'Inner Fence'
      CV_FENCH_OUTER ||= 'Outer Fence'

      ALL_OUT_SURFACE_STRC ||= [CVA_HOUSEX_WALLOUTER, CVA_ROOFGABLE, CVA_ROOFSLOPE, CVA_ROOFSOFFIT_OUTTER, CVA_HOUSEX_FLOOR,
                                CVA_WATER_TOP, CVA_GRASSLAND_TOP, CVA_ROCKERY_TOP,CV_FENCH_INNER,CV_FENCH_OUTER]


    end

    module Ratio3DConstant
      RATIO_DIAGONAL2ENTRANCE_TRIANGLE_HEIGHT ||= 0.1
      RATIO_ENTRANCE_PADDING ||= 0.1
      RATIO_HOUSE_ENTRANCE_PADDING ||= 0.2
      RATIO_ENTRANCE_HEIGHT ||= 0.15
      RATIO_HOUSE_ENTRANCE_HEIGHT ||= 0.8
    end

    module AttrManuscriptConstant
      CV_MODE_WALL ||= ["High wall", "Low wall"]
      DISC_MODE_WALL ||= {:high => CV_MODE_WALL[0], :low => CV_MODE_WALL[1]}
      CV_MODE_BRIDGE ||= ["High bridge", "Low bridge"]
      DISC_MODE_BRIDGE ||= {:high => CV_MODE_BRIDGE[0],
                            :low => CV_MODE_BRIDGE[1]
      }
      RADIUS_MODE_BRIDGE ||= {:high => 1.2.m,
                              :low => 1.0.m / 2
      }

      OPT_HOUSE_MAT ||= ["Brickwork (Standard)",
                         "Wood Wool Slab",
                         "Brickwork"]
      OPT_HOUSE_MAT_NAME ||= ["Brick and timber",
                         "Timber",
                         "Brick and stone"]
      OPT_COLOR_HOUSE_MAT ||= ["DimGray", "Chocolate", "DarkRed"]

      OPT_HOUSE_DOOR_TYPE ||= ["Plank door", "Frame door", "Open entrance"]

      DISC_OPT_HOUSE_DOOR_TYPE ||= {:plank => OPT_HOUSE_DOOR_TYPE[0],
                                    :frame => OPT_HOUSE_DOOR_TYPE[1],
                                    :open => OPT_HOUSE_DOOR_TYPE[2]
      }
      OPT_COLOR_HOUSE_DOOR_TYPE ||= ["Chocolate", "DimGray", "DarkRed"]

      OPT_HOUSE_DOOR_SCAL ||= ["Intermediate", "Fully open"]

      OPT_HOUSE_WINDOW_TYPE ||= ["Frame window", "Manchuria window"]
      DIST_HOUSE_WINDOW_TYPE ||= {:frame => OPT_HOUSE_WINDOW_TYPE[0], :manchuria => OPT_HOUSE_WINDOW_TYPE[1]}
      OPT_TEXT_HOUSE_WINDOW_TYPE ||= ["FRAME", "MANCHURIA"]
      OPT_COLOR_HOUSE_WINDOW_TYPE ||= ["Chocolate", "DarkRed"]
      OPT_HOUSE_WINDOW_SCAL ||= ["Single window", "Row of windows"]
      DIST_HOUSE_WINDOW_SCAL ||= {:middle => OPT_HOUSE_WINDOW_SCAL[0],
                                  :all => OPT_HOUSE_WINDOW_SCAL[1]}
      LIST_QUADS_RATIO_HOUSE_WINDOW_TYPE ||= [0.2, 0.5]
      OPT_HOPENING_DEG ||= ["Enclosed", "Permeable"]

      LIST_HOUSE_FLOOR_NUM_LIMIT ||= 3
      DIST_HOUSE_FLOOR_INFO ||= {:floor_num_limit => 2,
                                 :height_nontop => 2.8,
                                 :height_top => 2.5}

      LIST_ERROR ||= '_'
      CV_ROOF_GABLE = 'Gable roof'
      CV_ROOF_SADDLE = 'Saddle roof'
      CV_ROOF_HIP = 'Hip roof'
      CV_ROOF_FLAT_PARAPET = 'Flat roof with parapet'
      LIST_HOUSE_ROOF_TYPE_STANDARD ||= ["Hip roof", "Gable roof", "Saddle roof", "Flat roof with parapet"]
      LIST_HOUSE_ROOF_TYPE_REPOLYGON ||= ["Mansard roof", "Conical roof"]
      LIST_HOUSE_ROOF_TYPE_IRREGULAR ||= ["Hip roof", "Flat roof", "Flat roof with parapet"]
      LIST_TEXT_HOUSE_ROOF_TYPE ||= ["Gabbled Roof", "Suspension Roof", "Saddle Roof", "Pointed Roof", "Conical Roof", "Flat Roof"]
      LIST_COLOR_HOUSE_ROOF_TYPE ||= ["Chocolate", "DimGray", "DarkRed", 'IndianRed']

      SYM_STD ||= "Rectangular Foundation"
      SYM_REPOLYGON ||= "Regular Polygon Foundation"
      SYM_FREE ||= "Free Form Foundation"
      DIST_HOUSE_ROOF_TYPE ||= {
          SYM_STD => LIST_HOUSE_ROOF_TYPE_STANDARD,
          SYM_REPOLYGON => LIST_HOUSE_ROOF_TYPE_REPOLYGON,
          SYM_FREE => LIST_HOUSE_ROOF_TYPE_IRREGULAR
      }
    end

    module DistHouse3DConstant
      BASE_HEIGHT ||= 0.24.m
      BASE_PROTRUSION_WID ||= 0.0.m
      ROOF_HIP_DEFAULT_INDENT_LENGTH ||= 1.5.m

      ROOF_SOFFIT_HEIGHT ||= 0.2.m

      GABLE_HEIGHT_DEFAULT ||= 1.0.m
      GABLE_CORRIDOR_HEIGHT_DEFAULT ||= 0.5.m

      DOOR_LIMIT ||= 0.9.m
      WINDOW_LIMIT ||= 0.6.m
      WALL_WIDTH ||= 0.24.m

      SILL_FRAME_HEIGHT ||= 1.1.m
      WINDOW_FRAME_HEIGHT ||= 0.7.m
      WINDOW_FRAME_WIDTH ||= 0.7.m
      WINDOW_FRAME_INTERVAL ||= 2.0.m

      SILL_MANC_HEIGHT ||= 0.7.m
      WINDOW_MANC_HEIGHT ||= 1.2.m
      WINDOW_MANC_WIDTH ||= 1.5.m
      WINDOW_MANC_INTERVAL ||= 1.0.m

      DOOR_PLANK_HEIGHT ||= 2.0.m
      DOOR_PLANK_WIDTH ||= 0.9.m

      DOOR_FRAME_HEIGHT ||= 2.0.m
      DOOR_FRAME_WIDTH ||= 2.0.m

      DOOR_OPEN_HEIGHT ||= 2.0.m
      DOOR_OPEN_WIDTH_DLIMIT ||= 2.0.m
      DOOR_OPEN_MARGIN ||= 1.0.m
      DOOR_OPEN_INTERVAL ||= 0.24.m
      DOOR_OPEN_BAY_LIMIT1 ||= 3.0.m
      DOOR_OPEN_BAY_LIMIT2 ||= 5.0.m
      DOOR_OPEN_BAY_SMALL ||= 1.5.m

      LENGHT_BRIDGE_STAIR ||= 0.6.m
      HEIGHT_BRIDGE_STAIR ||= 0.4.m

      STAIRWELL_WIDTH ||= 1.0.m
      CORRIDOR_ROOF_SOFFIT_WIDTH ||= ROOF_SOFFIT_HEIGHT

      COLUMN_INTERVAL ||= 4.0.m
      COLUMN_END_INTERVAL ||= CORRIDOR_ROOF_SOFFIT_WIDTH * 2
      GROUND_DEPTH ||= 0.70.m

      HEIGHT_WALL_PERMEABLE ||= 0.24.m

      TREE_HEIGHT_PRED ||= 5.0.m
      MOUNTAIN_HEIGHT_PRED ||= 10.0.m
      DEPTH_WATER_BODY ||= 0.24.m
      DEPTH_ROAD_BODY ||= 0.24.m
      DEPTH_ROCKERY_BODY ||= 0.24.m
      DEPTH_WATER_SURFACE ||= 0.24.m
      DEPTH_ROAD_SURFACE ||= 0.24.m
      DEPTH_GRASSLAND_BODY ||= 0.24.m
      DEPTH_PATCH_BODY ||= 0.24.m

      DIST_CORRIDOR_DEFAULT ||= 1.m
      DIST_ROAD_DEFAULT ||= 5.m
      DIST_WALL_DEFAULT ||= 0.24.m / 2
      DIST_HCORRIDOR_DEFAULT ||= 0.5.m
      DIST_CORRIDOR_LOWER_LIMIT ||= 0.24.m
      DIST_CORRIDOR_UPPER_LIMIT ||= 20.m
    end

    module MaskConstant
      SKY = '5 Open-air'
      GRY = '4 Grey'
      ABR_INNER = '3 In the tree'
      ABR = '2 Below tree'
      BLD = '1 Building'
      NUN = '0 Exclude'
      N_SKY = 5
      N_GRY = 4
      N_ABR_INNER = 3
      N_ABR = 2
      N_BLD = 1
      N_NUN = 0
    end
  end

  # '天空5', '座位4', '树荫3', '灰空间2', '无效1', '建筑0'

  # Purpose: 【alias】
  STR_C = ContantLib::StructConstant
  MASK_C = ContantLib::MaskConstant
  MAT_C = ContantLib::MaterialConstant
  KEY_C = ContantLib::KeyConstant
  VAL_C = ContantLib::ValConstant
  PAM_C = ContantLib::ParamConstant
  TYP_C = ContantLib::TypeConstant
  CLR_C = ContantLib::ColorConstant
  CLR_NAME_C = ContantLib::ColorNameConstant
  GEO_C = ContantLib::GeomConstant
  DIS_3D_C = ContantLib::DistHouse3DConstant
  RDO_3D_C = ContantLib::Ratio3DConstant
  KEY_3D_C = ContantLib::Key3DConstant
  KEY_MAT_TH_C = ContantLib::KeyMatThermalConstant
  ATTR_MAN_C = ContantLib::AttrManuscriptConstant
  TXT_C = ContantLib::TextConstant
  PAT_C = ContantLib::PathConstant
  PAT_TX_C = ContantLib::PathTextureConstant
  DICT_C = ContantLib::DictConstant

end
