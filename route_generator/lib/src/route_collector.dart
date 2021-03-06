import 'package:build/build.dart';
import 'package:route_annotation/route_annotation.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';

import 'real_route_page.dart';
import 'real_route_paramemter.dart';
import 'watch_state.dart';

const TypeChecker routePageChecker = TypeChecker.fromRuntime(RoutePage);
const TypeChecker routeGetterChecker = TypeChecker.fromRuntime(RouteField);
const TypeChecker pageRouteBuilderFunctionChecker =
    TypeChecker.fromRuntime(PageRouteBuilderFuntcion);
const TypeChecker routePageBuilderFunctionChecker =
    TypeChecker.fromRuntime(RoutePageBuilderFunction);
const TypeChecker routeTransitionBuilderFunctionChecker =
    TypeChecker.fromRuntime(RouteTransitionBuilderFunction);
const TypeChecker routeTransitionDurationGetterChecker =
    TypeChecker.fromRuntime(RouteTransitionDurationField);

class RouteCollector extends Generator {
  static const DEBUG = false;

  @override
  generate(LibraryReader library, BuildStep buildStep) async {
    final inputId = buildStep.inputId.toString();
    fileRoutes.putIfAbsent(inputId, () => {});
    final previous = Set<RealRoutePage>.from(fileRoutes[inputId]);
    fileRoutes[inputId].clear();
    for (var annotatedElement in library.annotatedWith(routePageChecker)) {
      final className = annotatedElement.element.displayName;
      final path = buildStep.inputId.path;
      final package = buildStep.inputId.package;
      final import = "package:$package/${path.replaceFirst('lib/', '')}";
      final classElement = library.findType(className);
      final route =
          resolveRoutePage(classElement, annotatedElement.annotation, import);
      routes.add(route);
      fileRoutes[inputId].add(route);
    }
    rewrite = true;
    final current = fileRoutes[inputId];
    if (current.length < previous.length) {
      final differences = previous.difference(current);
      routes.removeAll(differences.toList());
    }
    return null;
  }

  RealRoutePage resolveRoutePage(
      ClassElement classElement, ConstantReader annotation, String import) {
    final className = classElement.displayName;
    final isInitialRoute = annotation.peek("isInitialRoute").boolValue;

    final peekName = annotation.peek("name")?.stringValue ?? "/$className";
    final routeName = isInitialRoute ? "home" : peekName;

    List<RealRouteParameter> getParameters(ConstantReader value) {
      return value?.listValue
              ?.map((value) => RealRouteParameter(
                  value.getField("name").toStringValue(),
                  key: value.getField("key").toStringValue()))
              ?.toList() ??
          <RealRouteParameter>[];
    }

    final methods = classElement.methods;
    final fields = classElement.fields;
    String findStaticMethodNameByType(
        List<MethodElement> methods, TypeChecker checker) {
      return methods
          .firstWhere(
            (method) => method.isStatic && checker.hasAnnotationOf(method),
            orElse: () => null,
          )
          ?.displayName;
    }

    String findStaticFieldNameByType(
        List<FieldElement> fields, TypeChecker checker) {
      return fields
          .firstWhere(
            (field) => field.isStatic && checker.hasAnnotationOf(field),
            orElse: () => null,
          )
          ?.displayName;
    }

    String routeField;
    String pageRouteBuilderFuntcion;
    String routePageBuilderFunction;
    String routeTransitionBuilderFunction;
    String routeTransitionDurationField;

    routeField = findStaticFieldNameByType(fields, routeGetterChecker);
    if (routeField == null)
      pageRouteBuilderFuntcion =
          findStaticMethodNameByType(methods, pageRouteBuilderFunctionChecker);

    if (routeField == null && pageRouteBuilderFuntcion == null) {
      routePageBuilderFunction =
          findStaticMethodNameByType(methods, routePageBuilderFunctionChecker);
      routeTransitionBuilderFunction = findStaticMethodNameByType(
          methods, routeTransitionBuilderFunctionChecker);
      routeTransitionDurationField = findStaticFieldNameByType(
          fields, routeTransitionDurationGetterChecker);
    }

    return RealRoutePage(
      import,
      className,
      routeName,
      isInitialRoute: isInitialRoute,
      params: getParameters(annotation.peek("params")),
      routeField: routeField,
      pageRouteBuilderFunction: pageRouteBuilderFuntcion,
      routePageBuilderFunction: routePageBuilderFunction,
      routeTransitionBuilderFunction: routeTransitionBuilderFunction,
      routeTransitionDurationField: routeTransitionDurationField,
    );
  }
}
