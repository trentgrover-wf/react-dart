// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library react_client;

import "package:react/react.dart";
import "dart:js";
import "dart:html";
import "dart:async";

var _React = context['React'];
var _Object = context['Object'];

const PROPS = 'props';
const INTERNAL = '__internal__';
const COMPONENT = 'component';
const IS_MOUNTED = 'isMounted';
const REFS = 'refs';

newJsObjectEmpty() {
  return new JsObject(_Object);
}

final emptyJsMap = newJsObjectEmpty();
newJsMap(Map map) {
  var JsMap = newJsObjectEmpty();
  for (var key in map.keys) {
    if(map[key] is Map) {
      JsMap[key] = newJsMap(map[key]);
    } else {
      JsMap[key] = map[key];
    }
  }
  return JsMap;
}

class ReactJSComponent extends Component {

  JsObject _source;

  ReactJSComponent(JsObject source) {
    _source = source;

    getDOMNode = () => _source.callMethod('getDOMNode');

    ref = (name) {
      var ref = _source['refs'][name] as JsObject;
      return new ReactJSComponent(ref);
    };
  }

//  noSuchMethod(Invocation invocation) {
//    /** fall back to underlying JS method if it exists */
//    // TODO - do this without the mirror getName...
//    return _source.callMethod(MirrorSystem.getName(invocation.memberName), invocation.positionalArguments);
//  }
}

/**
 * Type of [children] must be child or list of childs, when child is JsObject or String
 */
typedef JsObject ReactComponentFactory(Map props, [dynamic children]);
typedef Component ComponentFactory();

class ReactComponentFactoryProxy implements Function {
  final ReactComponentFactory _call;
  ReactComponentFactoryProxy(this._call);

  JsObject call(Map props, [dynamic children]) {
    return this._call(props, children);
  }
}

/** TODO Think about using Expandos */
_getInternalProps(JsObject jsProps) => jsProps[INTERNAL][PROPS];

ReactComponentFactory _registerComponent(ComponentFactory componentFactory, [Iterable<String> skipMethods = const []]) {

  Component component = componentFactory();

  /**
   * // TODO - looks like this description belongs with the getInitialState implementation instead...
   * wrapper for getDefaultProps.
   * Get internal, create component and place it to internal.
   *
   * Next get default props by component method and merge component.props into it
   * to update it with passed props from parent.
   *
   * @return jsProps with internal with component.props and component
   */
  var getDefaultProps = new JsFunction.withThis((jsThis) {
//    print('DART - getDefaultProps');
//    return newJsObjectEmpty();
//    var defProps = newJsObjectEmpty();
//    defProps[INTERNAL] = {PROPS: component.getDefaultProps()};
    return newJsMap(component.getDefaultProps());
  });

  /**
   * get initial state from component.getInitialState, put them to state.
   *
   * @return empty JsObject as default state for javascript react component
   */
  var getInitialState = new JsFunction.withThis((jsThis) {
//    print('DART - getInitialState');
/*
    var redraw = () {
      if (jsThis.callMethod('isMounted')) {
        jsThis.callMethod('setState', [emptyJsMap]);
      }
    };

    var getRef = (name) {
      var ref = jsThis['refs'][name] as JsObject;
      return new ReactJSComponent(ref);
    };

    var getDOMNode = () {
      return jsThis.callMethod("getDOMNode");
    };

    // init the rest of the component here because we need access to jsThis
    component
      ..initComponentInternal(redraw, getRef, getDOMNode)
      ..initStateInternal();
*/
    // this is the actual return value of this base method
//    return newJsObjectEmpty();
    return newJsMap(component.getInitialState());
  });

  /**
   * only wrap componentWillMount
   */
  var componentWillMount = new JsFunction.withThis((jsThis) {
//    print('DART - componentWillMount');
//    component
//        ..componentWillMount()
//        ..transferComponentState();
    component.componentWillMount();
  });

  /**
   * only wrap componentDidMount
   */
  var componentDidMount = new JsFunction.withThis((jsThis) {
//    print('DART - componentDidMount');
    component.componentDidMount();
  });

  _getNextProps(Component component, newArgs) {
    var newProps = _getInternalProps(newArgs);
    return {}
//      ..addAll(component.getDefaultProps())
      ..addAll(newProps != null ? newProps : {});
  }

  _afterPropsChange(Component component, newArgs) {
    /** add component to newArgs to keep component in internal */
//    newArgs[INTERNAL][COMPONENT] = component;

    /** update component.props */
    component.props = _getNextProps(component, newArgs);

    /** update component.state */
//    component.transferComponentState();
  }

  /**
   * Wrap componentWillReceiveProps
   */
  var componentWillReceiveProps =
      new JsFunction.withThis((jsThis, newArgs, [reactInternal]) {
//        print('DART - componentWillReceiveProps');
//    component.componentWillReceiveProps(_getNextProps(component, newArgs));
        component.componentWillReceiveProps(newArgs);
  });

  /**
   * count nextProps from jsNextProps, get result from component,
   * and if shoudln't update, update props and transfer state.
   */
  var shouldComponentUpdate =
      new JsFunction.withThis((jsThis, newArgs, nextState, nextContext) {
//        print('DART - shouldComponentUpdate');
//      return component.shouldComponentUpdate(newArgs, nextState);
    /** use component.nextState where are stored nextState */
    if (component.shouldComponentUpdate(_getNextProps(component, newArgs),
                                        component.nextState)) {
      return true;
    } else {
      /**
       * if component shouldn't update, update props and transfer state,
       * because willUpdate will not be called and so it will not do it.
       */
      _afterPropsChange(component, newArgs);
      return false;
    }
  });

  /**
   * wrap component.componentWillUpdate and after that update props and transfer state
   */
  var componentWillUpdate =
      new JsFunction.withThis((jsThis, newArgs, nextState, [reactInternal]) {
//        print('DART - componentWillUpdate');
//      component.componentWillUpdate(newArgs, nextState);
    component.componentWillUpdate(_getNextProps(component, newArgs),
                                  component.nextState);
    _afterPropsChange(component, newArgs);
  });

  /**
   * wrap componentDidUpdate and use component.prevState which was trasnfered from state in componentWillUpdate.
   */
  var componentDidUpdate =
      new JsFunction.withThis((jsThis, prevProps, prevState, prevContext) {
        component.componentDidUpdate(prevProps, prevState);
//        print('DART - componentDidUpdate');
//    var prevInternalProps = _getInternalProps(prevProps);
//    component.componentDidUpdate(prevInternalProps, component.prevState);
  });

  /**
   * only wrap componentWillUnmount
   */
  var componentWillUnmount =
      new JsFunction.withThis((jsThis, [reactInternal]) {
//        print('DART - componentWillUnmount');
    component.componentWillUnmount();
  });

  /**
   * only wrap render
   */
  var render = new JsFunction.withThis((jsThis) {
//    print('DART - render');
//    return component.render();
    return component.render();
  });

  var skipableMethods = ['componentDidMount', 'componentWillReceiveProps',
                         'shouldComponentUpdate', 'componentDidUpdate',
                         'componentWillUnmount'];

  removeUnusedMethods(Map originalMap, Iterable removeMethods) {
    removeMethods.where((m) => skipableMethods.contains(m)).forEach((m) => originalMap.remove(m));
    return originalMap;
  }

  /**
   * create reactComponent with wrapped functions
   */
  JsFunction reactComponentFactory = _React.callMethod('createFactory', [
    _React.callMethod('createClass', [newJsMap(
      removeUnusedMethods({
        'componentWillMount': componentWillMount,
        'componentDidMount': componentDidMount,
        'componentWillReceiveProps': componentWillReceiveProps,
        'shouldComponentUpdate': shouldComponentUpdate,
        'componentWillUpdate': componentWillUpdate,
        'componentDidUpdate': componentDidUpdate,
        'componentWillUnmount': componentWillUnmount,
        'getDefaultProps': getDefaultProps,
        'getInitialState': getInitialState,
        'render': render
      }, skipMethods)
    )])
  ]);

  var call = (Map props, [dynamic children]) {

    if (children == null) {
      children = [];
    } else if (children is! Iterable) {
      children = [children];
    }

    var convertedArgs = newJsObjectEmpty();

    /**
     * add key to args which will be passed to javascript react component
     */
    if (props.containsKey('key')) {
      convertedArgs['key'] = props['key'];
    }
    if (props.containsKey('ref')) {
      convertedArgs['ref'] = props['ref'];
    }

    /**
     * put props to internal part of args
     */
    convertedArgs[INTERNAL] = {PROPS: props};

    return reactComponentFactory.apply([convertedArgs, children]);
  };

  /**
   * return ReactComponentFactory which produce react component with set props and children[s]
   */
  return new ReactComponentFactoryProxy(call);
}


/**
 * create dart-react registered component for html tag.
 */
_reactDom(String name) {
  var call = (Map props, [dynamic children]) {
    _convertBoundValues(props);
    _convertEventHandlers(props);
    if (props.containsKey('style')) {
      props['style'] = new JsObject.jsify(props['style']);
    }
    if (children is Iterable) {
      children = new JsArray.from(children);
    }
    return _React['createElement'].apply([name, newJsMap(props), children]);
  };

  return new ReactComponentFactoryProxy(call);
}

/**
 * Recognize if type of input (or other element) is checkbox by it's props.
 */
_isCheckbox(props) {
  return props['type'] == 'checkbox';
}

/**
 * get value from DOM element.
 *
 * If element is checkbox, return bool, else return value of "value" attribute
 */
_getValueFromDom(domElem) {
  var props = domElem.attributes;
  if (_isCheckbox(props)) {
    return domElem.checked;
  } else {
    return domElem.value;
  }
}

/**
 * set value to props based on type of input.
 *
 * Checkbox is a special case.
 */
_setValueToProps(Map props, val) {
  if (_isCheckbox(props)) {
    if(val) {
      props['checked'] = true;
    } else {
      if(props.containsKey('checked')) {
         props.remove('checked');
      }
    }
  } else {
    props['value'] = val;
  }
}

/**
 * convert bound values to pure value
 * and packed onchanged function
 */
_convertBoundValues(Map args) {
  var boundValue = args['value'];
  if (args['value'] is List) {
    _setValueToProps(args, boundValue[0]);
    args['value'] = boundValue[0];
    var onChange = args["onChange"];
    /**
     * put new function into onChange event handler.
     *
     * If there was something listening for that event,
     * trigger it and return its return value.
     */
    args['onChange'] = (e) {
      boundValue[1](_getValueFromDom(e.target));
      if(onChange != null)
        return onChange(e);
    };
  }
}


/**
 * Convert event pack event handler into wrapper
 * and pass it only dart object of event
 * converted from JsObject of event.
 */
_convertEventHandlers(Map args) {
  args.forEach((key, value) {
    var eventFactory;
    if (_syntheticClipboardEvents.contains(key)) {
      eventFactory = syntheticClipboardEventFactory;
    } else if (_syntheticKeyboardEvents.contains(key)) {
      eventFactory = syntheticKeyboardEventFactory;
    } else if (_syntheticFocusEvents.contains(key)) {
      eventFactory = syntheticFocusEventFactory;
    } else if (_syntheticFormEvents.contains(key)) {
      eventFactory = syntheticFormEventFactory;
    } else if (_syntheticMouseEvents.contains(key)) {
      eventFactory = syntheticMouseEventFactory;
    } else if (_syntheticTouchEvents.contains(key)) {
      eventFactory = syntheticTouchEventFactory;
    } else if (_syntheticUIEvents.contains(key)) {
      eventFactory = syntheticUIEventFactory;
    } else if (_syntheticWheelEvents.contains(key)) {
      eventFactory = syntheticWheelEventFactory;
    } else return;
    args[key] = (JsObject e, [String domId]) => value(eventFactory(e));
  });
}

SyntheticEvent syntheticEventFactory(JsObject e) {
  return new SyntheticEvent(e["bubbles"], e["cancelable"], e["currentTarget"],
      e["defaultPrevented"], () => e.callMethod("preventDefault", []),
      () => e.callMethod("stopPropagation", []), e["eventPhase"], e["isTrusted"], e["nativeEvent"],
      e["target"], e["timeStamp"], e["type"]);
}

SyntheticEvent syntheticClipboardEventFactory(JsObject e) {
  return new SyntheticClipboardEvent(e["bubbles"], e["cancelable"], e["currentTarget"],
      e["defaultPrevented"], () => e.callMethod("preventDefault", []),
      () => e.callMethod("stopPropagation", []), e["eventPhase"], e["isTrusted"], e["nativeEvent"],
      e["target"], e["timeStamp"], e["type"], e["clipboardData"]);
}

SyntheticEvent syntheticKeyboardEventFactory(JsObject e) {
  return new SyntheticKeyboardEvent(e["bubbles"], e["cancelable"], e["currentTarget"],
      e["defaultPrevented"], () => e.callMethod("preventDefault", []),
      () => e.callMethod("stopPropagation", []), e["eventPhase"], e["isTrusted"],
      e["nativeEvent"], e["target"], e["timeStamp"], e["type"], e["altKey"],
      e["char"], e["charCode"], e["ctrlKey"], e["locale"], e["location"],
      e["key"], e["keyCode"], e["metaKey"], e["repeat"], e["shiftKey"]);
}

SyntheticEvent syntheticFocusEventFactory(JsObject e) {
  return new SyntheticFocusEvent(e["bubbles"], e["cancelable"], e["currentTarget"],
      e["defaultPrevented"], () => e.callMethod("preventDefault", []),
      () => e.callMethod("stopPropagation", []), e["eventPhase"], e["isTrusted"], e["nativeEvent"],
      e["target"], e["timeStamp"], e["type"], e["relatedTarget"]);
}

SyntheticEvent syntheticFormEventFactory(JsObject e) {
  return new SyntheticFormEvent(e["bubbles"], e["cancelable"], e["currentTarget"],
      e["defaultPrevented"], () => e.callMethod("preventDefault", []),
      () => e.callMethod("stopPropagation", []), e["eventPhase"], e["isTrusted"], e["nativeEvent"],
      e["target"], e["timeStamp"], e["type"]);
}

SyntheticDataTransfer syntheticDataTransferFactory(JsObject dt) {
  if (dt == null) return null;
  List<File> files = [];
  for (int i = 0; i < dt["files"]["length"]; i++) {
    files.add(dt["files"][i]);
  }
  List<String> types = [];
  for (int i = 0; i < dt["types"]["length"]; i++) {
    types.add(dt["types"][i]);
  }
  return new SyntheticDataTransfer(dt["dropEffect"], dt["effectAllowed"], files, types);
}

SyntheticEvent syntheticMouseEventFactory(JsObject e) {
  SyntheticDataTransfer dt = syntheticDataTransferFactory(e["dataTransfer"]);
  return new SyntheticMouseEvent(e["bubbles"], e["cancelable"], e["currentTarget"],
      e["defaultPrevented"], () => e.callMethod("preventDefault", []),
      () => e.callMethod("stopPropagation", []), e["eventPhase"], e["isTrusted"], e["nativeEvent"],
      e["target"], e["timeStamp"], e["type"], e["altKey"], e["button"], e["buttons"], e["clientX"], e["clientY"],
      e["ctrlKey"], dt, e["metaKey"], e["pageX"], e["pageY"], e["relatedTarget"], e["screenX"],
      e["screenY"], e["shiftKey"]);
}

SyntheticEvent syntheticTouchEventFactory(JsObject e) {
  return new SyntheticTouchEvent(e["bubbles"], e["cancelable"], e["currentTarget"],
      e["defaultPrevented"], () => e.callMethod("preventDefault", []),
      () => e.callMethod("stopPropagation", []), e["eventPhase"], e["isTrusted"], e["nativeEvent"],
      e["target"], e["timeStamp"], e["type"], e["altKey"], e["changedTouches"], e["ctrlKey"], e["metaKey"],
      e["shiftKey"], e["targetTouches"], e["touches"]);
}

SyntheticEvent syntheticUIEventFactory(JsObject e) {
  return new SyntheticUIEvent(e["bubbles"], e["cancelable"], e["currentTarget"],
      e["defaultPrevented"], () => e.callMethod("preventDefault", []),
      () => e.callMethod("stopPropagation", []), e["eventPhase"], e["isTrusted"], e["nativeEvent"],
      e["target"], e["timeStamp"], e["type"], e["detail"], e["view"]);
}

SyntheticEvent syntheticWheelEventFactory(JsObject e) {
  return new SyntheticWheelEvent(e["bubbles"], e["cancelable"], e["currentTarget"],
      e["defaultPrevented"], () => e.callMethod("preventDefault", []),
      () => e.callMethod("stopPropagation", []), e["eventPhase"], e["isTrusted"], e["nativeEvent"],
      e["target"], e["timeStamp"], e["type"], e["deltaX"], e["deltaMode"], e["deltaY"], e["deltaZ"]);
}

Set _syntheticClipboardEvents = new Set.from(["onCopy", "onCut", "onPaste",]);

Set _syntheticKeyboardEvents = new Set.from(["onKeyDown", "onKeyPress",
    "onKeyUp",]);

Set _syntheticFocusEvents = new Set.from(["onFocus", "onBlur",]);

Set _syntheticFormEvents = new Set.from(["onChange", "onInput", "onSubmit",
]);

Set _syntheticMouseEvents = new Set.from(["onClick", "onContextMenu",
    "onDoubleClick", "onDrag", "onDragEnd", "onDragEnter", "onDragExit",
    "onDragLeave", "onDragOver", "onDragStart", "onDrop", "onMouseDown",
    "onMouseEnter", "onMouseLeave", "onMouseMove", "onMouseOut", 
    "onMouseOver", "onMouseUp",]);

Set _syntheticTouchEvents = new Set.from(["onTouchCancel", "onTouchEnd",
    "onTouchMove", "onTouchStart",]);

Set _syntheticUIEvents = new Set.from(["onScroll",]);

Set _syntheticWheelEvents = new Set.from(["onWheel",]);


void _render(JsObject component, HtmlElement element) {
  _React.callMethod('render', [component, element]);
}

bool _unmountComponentAtNode(HtmlElement element) {
  return _React.callMethod('unmountComponentAtNode', [element]);
}

void setClientConfiguration() {
  _React.callMethod('initializeTouchEvents', [true]);
  setReactConfiguration(_reactDom, _registerComponent, _render, null, _unmountComponentAtNode);
}
