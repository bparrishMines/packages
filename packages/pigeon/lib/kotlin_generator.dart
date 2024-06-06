// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:graphs/graphs.dart';

import 'ast.dart';
import 'functional.dart';
import 'generator.dart';
import 'generator_tools.dart';
import 'kotlin/templates.dart';
import 'pigeon_lib.dart' show TaskQueueType;

/// Documentation open symbol.
const String _docCommentPrefix = '/**';

/// Documentation continuation symbol.
const String _docCommentContinuation = ' *';

/// Documentation close symbol.
const String _docCommentSuffix = ' */';

/// Documentation comment spec.
const DocumentCommentSpecification _docCommentSpec =
    DocumentCommentSpecification(
  _docCommentPrefix,
  closeCommentToken: _docCommentSuffix,
  blockContinuationToken: _docCommentContinuation,
);

/// Options that control how Kotlin code will be generated.
class KotlinOptions {
  /// Creates a [KotlinOptions] object
  const KotlinOptions({
    this.package,
    this.copyrightHeader,
    this.errorClassName,
    this.includeErrorClass = true,
  });

  /// The package where the generated class will live.
  final String? package;

  /// A copyright header that will get prepended to generated code.
  final Iterable<String>? copyrightHeader;

  /// The name of the error class used for passing custom error parameters.
  final String? errorClassName;

  /// Whether to include the error class in generation.
  ///
  /// This should only ever be set to false if you have another generated
  /// Kotlin file in the same directory.
  final bool includeErrorClass;

  /// Creates a [KotlinOptions] from a Map representation where:
  /// `x = KotlinOptions.fromMap(x.toMap())`.
  static KotlinOptions fromMap(Map<String, Object> map) {
    return KotlinOptions(
      package: map['package'] as String?,
      copyrightHeader: map['copyrightHeader'] as Iterable<String>?,
      errorClassName: map['errorClassName'] as String?,
      includeErrorClass: map['includeErrorClass'] as bool? ?? true,
    );
  }

  /// Converts a [KotlinOptions] to a Map representation where:
  /// `x = KotlinOptions.fromMap(x.toMap())`.
  Map<String, Object> toMap() {
    final Map<String, Object> result = <String, Object>{
      if (package != null) 'package': package!,
      if (copyrightHeader != null) 'copyrightHeader': copyrightHeader!,
      if (errorClassName != null) 'errorClassName': errorClassName!,
      'includeErrorClass': includeErrorClass,
    };
    return result;
  }

  /// Overrides any non-null parameters from [options] into this to make a new
  /// [KotlinOptions].
  KotlinOptions merge(KotlinOptions options) {
    return KotlinOptions.fromMap(mergeMaps(toMap(), options.toMap()));
  }
}

/// Options that control how Kotlin code will be generated for a specific
/// ProxyApi.
class KotlinProxyApiOptions {
  /// Construct a [KotlinProxyApiOptions].
  const KotlinProxyApiOptions({this.fullClassName, this.minAndroidApi});

  /// The name of the full runtime Kotlin class name (including the package).
  final String? fullClassName;

  /// The minimum Android api version.
  ///
  /// This adds the [RequiresApi](https://developer.android.com/reference/androidx/annotation/RequiresApi)
  /// annotations on top of any constructor, field, or method that references
  /// this element.
  final int? minAndroidApi;
}

/// Class that manages all Kotlin code generation.
class KotlinGenerator extends StructuredGenerator<KotlinOptions> {
  /// Instantiates a Kotlin Generator.
  const KotlinGenerator();

  @override
  void writeFilePrologue(
    KotlinOptions generatorOptions,
    Root root,
    Indent indent, {
    required String dartPackageName,
  }) {
    if (generatorOptions.copyrightHeader != null) {
      addLines(indent, generatorOptions.copyrightHeader!, linePrefix: '// ');
    }
    indent.writeln('// ${getGeneratedCodeWarning()}');
    indent.writeln('// $seeAlsoWarning');
    indent.writeln('@file:Suppress("UNCHECKED_CAST", "ArrayInDataClass")');
  }

  @override
  void writeFileImports(
    KotlinOptions generatorOptions,
    Root root,
    Indent indent, {
    required String dartPackageName,
  }) {
    indent.newln();
    if (generatorOptions.package != null) {
      indent.writeln('package ${generatorOptions.package}');
    }
    indent.newln();
    indent.writeln('import android.util.Log');
    indent.writeln('import io.flutter.plugin.common.BasicMessageChannel');
    indent.writeln('import io.flutter.plugin.common.BinaryMessenger');
    indent.writeln('import io.flutter.plugin.common.MessageCodec');
    indent.writeln('import io.flutter.plugin.common.StandardMessageCodec');
    indent.writeln('import java.io.ByteArrayOutputStream');
    indent.writeln('import java.nio.ByteBuffer');
  }

  @override
  void writeEnum(
    KotlinOptions generatorOptions,
    Root root,
    Indent indent,
    Enum anEnum, {
    required String dartPackageName,
  }) {
    indent.newln();
    addDocumentationComments(
        indent, anEnum.documentationComments, _docCommentSpec);
    indent.write('enum class ${anEnum.name}(val raw: Int) ');
    indent.addScoped('{', '}', () {
      enumerate(anEnum.members, (int index, final EnumMember member) {
        addDocumentationComments(
            indent, member.documentationComments, _docCommentSpec);
        final String nameScreamingSnakeCase = member.name
            .replaceAllMapped(
                RegExp(r'(?<=[a-z])[A-Z]'), (Match m) => '_${m.group(0)}')
            .toUpperCase();
        indent.write('$nameScreamingSnakeCase($index)');
        if (index != anEnum.members.length - 1) {
          indent.addln(',');
        } else {
          indent.addln(';');
        }
      });

      indent.newln();
      indent.write('companion object ');
      indent.addScoped('{', '}', () {
        indent.write('fun ofRaw(raw: Int): ${anEnum.name}? ');
        indent.addScoped('{', '}', () {
          indent.writeln('return values().firstOrNull { it.raw == raw }');
        });
      });
    });
  }

  @override
  void writeDataClass(
    KotlinOptions generatorOptions,
    Root root,
    Indent indent,
    Class classDefinition, {
    required String dartPackageName,
  }) {
    const List<String> generatedMessages = <String>[
      ' Generated class from Pigeon that represents data sent in messages.'
    ];
    indent.newln();
    addDocumentationComments(
        indent, classDefinition.documentationComments, _docCommentSpec,
        generatorComments: generatedMessages);
    indent.write('data class ${classDefinition.name} ');
    indent.addScoped('(', '', () {
      for (final NamedType element
          in getFieldsInSerializationOrder(classDefinition)) {
        _writeClassField(indent, element);
        if (getFieldsInSerializationOrder(classDefinition).last != element) {
          indent.addln(',');
        } else {
          indent.newln();
        }
      }
    });

    indent.addScoped(') {', '}', () {
      writeClassDecode(
        generatorOptions,
        root,
        indent,
        classDefinition,
        dartPackageName: dartPackageName,
      );
      writeClassEncode(
        generatorOptions,
        root,
        indent,
        classDefinition,
        dartPackageName: dartPackageName,
      );
    });
  }

  @override
  void writeClassEncode(
    KotlinOptions generatorOptions,
    Root root,
    Indent indent,
    Class classDefinition, {
    required String dartPackageName,
  }) {
    indent.write('fun toList(): List<Any?> ');
    indent.addScoped('{', '}', () {
      indent.write('return listOf<Any?>');
      indent.addScoped('(', ')', () {
        for (final NamedType field
            in getFieldsInSerializationOrder(classDefinition)) {
          String toWriteValue = '';
          final String fieldName = field.name;
          final String safeCall = field.type.isNullable ? '?' : '';
          if (field.type.isEnum) {
            toWriteValue = '$fieldName$safeCall.raw';
          } else {
            toWriteValue = fieldName;
          }
          indent.writeln('$toWriteValue,');
        }
      });
    });
  }

  @override
  void writeClassDecode(
    KotlinOptions generatorOptions,
    Root root,
    Indent indent,
    Class classDefinition, {
    required String dartPackageName,
  }) {
    final String className = classDefinition.name;

    indent.write('companion object ');
    indent.addScoped('{', '}', () {
      indent.writeln('@Suppress("LocalVariableName")');
      indent
          .write('fun fromList(${varNamePrefix}list: List<Any?>): $className ');

      indent.addScoped('{', '}', () {
        enumerate(getFieldsInSerializationOrder(classDefinition),
            (int index, final NamedType field) {
          final String listValue = '${varNamePrefix}list[$index]';
          final String fieldType = _kotlinTypeForDartType(field.type);

          if (field.type.isNullable) {
            if (field.type.isEnum) {
              indent.write('val ${field.name}: $fieldType? = ');
              indent.add('($listValue as Int?)?.let ');
              indent.addScoped('{ num ->', '}', () {
                indent.writeln('$fieldType.ofRaw(num)');
              });
            } else {
              indent.writeln(
                  'val ${field.name} = ${_cast(indent, listValue, type: field.type)}');
            }
          } else {
            if (field.type.isEnum) {
              indent.writeln(
                  'val ${field.name} = $fieldType.ofRaw($listValue as Int)!!');
            } else {
              indent.writeln(
                  'val ${field.name} = ${_cast(indent, listValue, type: field.type)}');
            }
          }
        });

        indent.write('return $className(');
        for (final NamedType field
            in getFieldsInSerializationOrder(classDefinition)) {
          final String comma =
              getFieldsInSerializationOrder(classDefinition).last == field
                  ? ''
                  : ', ';
          indent.add('${field.name}$comma');
        }
        indent.addln(')');
      });
    });
  }

  void _writeClassField(Indent indent, NamedType field) {
    addDocumentationComments(
        indent, field.documentationComments, _docCommentSpec);
    indent.write(
        'val ${field.name}: ${_nullSafeKotlinTypeForDartType(field.type)}');
    final String defaultNil = field.type.isNullable ? ' = null' : '';
    indent.add(defaultNil);
  }

  @override
  void writeApis(
    KotlinOptions generatorOptions,
    Root root,
    Indent indent, {
    required String dartPackageName,
  }) {
    if (root.apis.any((Api api) =>
        api is AstHostApi &&
        api.methods.any((Method it) => it.isAsynchronous))) {
      indent.newln();
    }
    super.writeApis(generatorOptions, root, indent,
        dartPackageName: dartPackageName);
  }

  /// Writes the code for a flutter [Api], [api].
  /// Example:
  /// class Foo(private val binaryMessenger: BinaryMessenger) {
  ///   fun add(x: Int, y: Int, callback: (Int?) -> Unit) {...}
  /// }
  @override
  void writeFlutterApi(
    KotlinOptions generatorOptions,
    Root root,
    Indent indent,
    AstFlutterApi api, {
    required String dartPackageName,
  }) {
    final bool isCustomCodec = getCodecClasses(api, root).isNotEmpty;
    if (isCustomCodec) {
      _writeCodec(indent, api, root);
    }

    const List<String> generatedMessages = <String>[
      ' Generated class from Pigeon that represents Flutter messages that can be called from Kotlin.'
    ];
    addDocumentationComments(indent, api.documentationComments, _docCommentSpec,
        generatorComments: generatedMessages);

    final String apiName = api.name;
    indent.write(
        'class $apiName(private val binaryMessenger: BinaryMessenger, private val messageChannelSuffix: String = "") ');
    indent.addScoped('{', '}', () {
      indent.write('companion object ');
      indent.addScoped('{', '}', () {
        indent.writeln('/** The codec used by $apiName. */');
        indent.write('val codec: MessageCodec<Any?> by lazy ');
        indent.addScoped('{', '}', () {
          if (isCustomCodec) {
            indent.writeln(_getCodecName(api));
          } else {
            indent.writeln('StandardMessageCodec()');
          }
        });
      });

      for (final Method method in api.methods) {
        _writeFlutterMethod(
          indent,
          generatorOptions: generatorOptions,
          name: method.name,
          parameters: method.parameters,
          returnType: method.returnType,
          channelName: makeChannelName(api, method, dartPackageName),
          documentationComments: method.documentationComments,
          dartPackageName: dartPackageName,
          onWriteBody: (
            Indent indent, {
            required List<Parameter> parameters,
            required TypeDeclaration returnType,
            required String channelName,
            required String errorClassName,
          }) {
            indent.writeln(
              r'val separatedMessageChannelSuffix = if (messageChannelSuffix.isNotEmpty()) ".$messageChannelSuffix" else ""',
            );
            _writeFlutterMethodMessageCall(
              indent,
              parameters: parameters,
              returnType: returnType,
              channelName: '$channelName\$separatedMessageChannelSuffix',
              errorClassName: errorClassName,
            );
          },
        );
      }
    });
  }

  /// Write the kotlin code that represents a host [Api], [api].
  /// Example:
  /// interface Foo {
  ///   Int add(x: Int, y: Int);
  ///   companion object {
  ///     fun setUp(binaryMessenger: BinaryMessenger, api: Api) {...}
  ///   }
  /// }
  ///
  @override
  void writeHostApi(
    KotlinOptions generatorOptions,
    Root root,
    Indent indent,
    AstHostApi api, {
    required String dartPackageName,
  }) {
    final String apiName = api.name;

    final bool isCustomCodec = getCodecClasses(api, root).isNotEmpty;
    if (isCustomCodec) {
      _writeCodec(indent, api, root);
    }

    const List<String> generatedMessages = <String>[
      ' Generated interface from Pigeon that represents a handler of messages from Flutter.'
    ];
    addDocumentationComments(indent, api.documentationComments, _docCommentSpec,
        generatorComments: generatedMessages);

    indent.write('interface $apiName ');
    indent.addScoped('{', '}', () {
      for (final Method method in api.methods) {
        _writeMethodDeclaration(
          indent,
          name: method.name,
          documentationComments: method.documentationComments,
          returnType: method.returnType,
          parameters: method.parameters,
          isAsynchronous: method.isAsynchronous,
        );
      }

      indent.newln();
      indent.write('companion object ');
      indent.addScoped('{', '}', () {
        indent.writeln('/** The codec used by $apiName. */');
        indent.write('val codec: MessageCodec<Any?> by lazy ');
        indent.addScoped('{', '}', () {
          if (isCustomCodec) {
            indent.writeln(_getCodecName(api));
          } else {
            indent.writeln('StandardMessageCodec()');
          }
        });
        indent.writeln(
            '/** Sets up an instance of `$apiName` to handle messages through the `binaryMessenger`. */');
        indent.writeln('@JvmOverloads');
        indent.write(
            'fun setUp(binaryMessenger: BinaryMessenger, api: $apiName?, messageChannelSuffix: String = "") ');
        indent.addScoped('{', '}', () {
          indent.writeln(
              r'val separatedMessageChannelSuffix = if (messageChannelSuffix.isNotEmpty()) ".$messageChannelSuffix" else ""');
          for (final Method method in api.methods) {
            _writeHostMethodMessageHandler(
              indent,
              name: method.name,
              channelName:
                  '${makeChannelName(api, method, dartPackageName)}\$separatedMessageChannelSuffix',
              taskQueueType: method.taskQueueType,
              parameters: method.parameters,
              returnType: method.returnType,
              isAsynchronous: method.isAsynchronous,
            );
          }
        });
      });
    });
  }

  @override
  void writeInstanceManager(
    KotlinOptions generatorOptions,
    Root root,
    Indent indent, {
    required String dartPackageName,
  }) {
    indent.format(instanceManagerTemplate);
  }

  @override
  void writeInstanceManagerApi(
    KotlinOptions generatorOptions,
    Root root,
    Indent indent, {
    required String dartPackageName,
  }) {
    const String instanceManagerApiName = '${instanceManagerClassName}Api';

    final String removeStrongReferenceName = makeChannelNameWithStrings(
      apiName: instanceManagerApiName,
      methodName: 'removeStrongReference',
      dartPackageName: dartPackageName,
    );
    final String clearName = makeChannelNameWithStrings(
      apiName: instanceManagerApiName,
      methodName: 'clear',
      dartPackageName: dartPackageName,
    );

    addDocumentationComments(
      indent,
      <String>[
        'Generated API for managing the Dart and native `$instanceManagerClassName`s.',
      ],
      _docCommentSpec,
    );
    indent.writeScoped(
      'private class $instanceManagerApiName(val binaryMessenger: BinaryMessenger) {',
      '}',
      () {
        indent.writeScoped('companion object {', '}', () {
          addDocumentationComments(
            indent,
            <String>['The codec used by $instanceManagerApiName.'],
            _docCommentSpec,
          );
          indent.writeScoped('val codec: MessageCodec<Any?> by lazy {', '}',
              () {
            indent.writeln('StandardMessageCodec()');
          });
          indent.newln();

          addDocumentationComments(
            indent,
            <String>[
              'Sets up an instance of `$instanceManagerApiName` to handle messages from the',
              '`binaryMessenger`.',
            ],
            _docCommentSpec,
          );
          indent.writeScoped(
            'fun setUpMessageHandlers(binaryMessenger: BinaryMessenger, instanceManager: $instanceManagerClassName?) {',
            '}',
            () {
              const String setHandlerCondition = 'instanceManager != null';
              _writeHostMethodMessageHandler(
                indent,
                name: 'removeStrongReference',
                channelName: removeStrongReferenceName,
                taskQueueType: TaskQueueType.serial,
                parameters: <Parameter>[
                  Parameter(
                    name: 'identifier',
                    type: const TypeDeclaration(
                      baseName: 'int',
                      isNullable: false,
                    ),
                  ),
                ],
                returnType: const TypeDeclaration.voidDeclaration(),
                setHandlerCondition: setHandlerCondition,
                onCreateCall: (
                  List<String> safeArgNames, {
                  required String apiVarName,
                }) {
                  return 'instanceManager.remove<Any?>(${safeArgNames.single})';
                },
              );
              _writeHostMethodMessageHandler(
                indent,
                name: 'clear',
                channelName: clearName,
                taskQueueType: TaskQueueType.serial,
                parameters: <Parameter>[],
                returnType: const TypeDeclaration.voidDeclaration(),
                setHandlerCondition: setHandlerCondition,
                onCreateCall: (
                  List<String> safeArgNames, {
                  required String apiVarName,
                }) {
                  return 'instanceManager.clear()';
                },
              );
            },
          );
        });
        indent.newln();

        _writeFlutterMethod(
          indent,
          generatorOptions: generatorOptions,
          name: 'removeStrongReference',
          parameters: <Parameter>[
            Parameter(
              name: 'identifier',
              type: const TypeDeclaration(baseName: 'int', isNullable: false),
            )
          ],
          returnType: const TypeDeclaration.voidDeclaration(),
          channelName: removeStrongReferenceName,
          dartPackageName: dartPackageName,
        );
      },
    );
  }

  @override
  void writeProxyApiBaseCodec(
    KotlinOptions generatorOptions,
    Root root,
    Indent indent,
  ) {
    final Iterable<AstProxyApi> allProxyApis =
        root.apis.whereType<AstProxyApi>();

    _writeProxyApiRegistrar(indent, allProxyApis: allProxyApis);

    const String codecName = '${classNamePrefix}ProxyApiBaseCodec';

    // Sort APIs where edges are an API's super class and interfaces.
    //
    // This sorts the APIs to have child classes be listed before their parent
    // classes. This prevents the scenario where a method might return the super
    // class of the actual class, so the incorrect Dart class gets created
    // because the 'value is <SuperClass>' was checked first in the codec. For
    // example:
    //
    // class Shape {}
    // class Circle extends Shape {}
    //
    // class SomeClass {
    //   Shape giveMeAShape() => Circle();
    // }
    final List<AstProxyApi> sortedApis = topologicalSort(
      allProxyApis,
      (AstProxyApi api) {
        return <AstProxyApi>[
          if (api.superClass?.associatedProxyApi != null)
            api.superClass!.associatedProxyApi!,
          ...api.interfaces.map(
            (TypeDeclaration interface) => interface.associatedProxyApi!,
          ),
        ];
      },
    );

    indent.writeScoped(
      'private class $codecName(val registrar: PigeonProxyApiRegistrar) : StandardMessageCodec() {',
      '}',
      () {
        indent.format(
          '''
          override fun readValueOfType(type: Byte, buffer: ByteBuffer): Any? {
            return when (type) {
              128.toByte() -> {
                return registrar.instanceManager.getInstance(
                    readValue(buffer).let { if (it is Int) it.toLong() else it as Long })
              }
              else -> super.readValueOfType(type, buffer)
            }
          }''',
          trimIndentation: true,
        );
        indent.newln();

        indent.writeScoped(
          'override fun writeValue(stream: ByteArrayOutputStream, value: Any?) {',
          '}',
          () {
            enumerate(
              sortedApis,
              (int index, AstProxyApi api) {
                final String className =
                    api.kotlinOptions?.fullClassName ?? api.name;

                final int? minApi = api.kotlinOptions?.minAndroidApi;
                final String versionCheck = minApi != null
                    ? 'android.os.Build.VERSION.SDK_INT >= $minApi && '
                    : '';

                indent.format(
                  '''
                  ${index > 0 ? ' else ' : ''}if (${versionCheck}value is $className) {
                    registrar.get$hostProxyApiPrefix${api.name}().${classMemberNamePrefix}newInstance(value) { }
                  }''',
                  trimIndentation: true,
                );
              },
            );
            indent.newln();

            indent.format(
              '''
              when {
                registrar.instanceManager.containsInstance(value) -> {
                  stream.write(128)
                  writeValue(stream, registrar.instanceManager.getIdentifierForStrongReference(value))
                }
                else -> super.writeValue(stream, value)
              }''',
              trimIndentation: true,
            );
          },
        );
      },
    );
  }

  @override
  void writeProxyApi(
    KotlinOptions generatorOptions,
    Root root,
    Indent indent,
    AstProxyApi api, {
    required String dartPackageName,
  }) {
    final String kotlinApiName = '$hostProxyApiPrefix${api.name}';

    addDocumentationComments(
      indent,
      api.documentationComments,
      _docCommentSpec,
    );
    indent.writeln('@Suppress("UNCHECKED_CAST")');
    // The API only needs to be abstract if there are methods to override.
    final String classModifier =
        api.hasAnyHostMessageCalls() || api.unattachedFields.isNotEmpty
            ? 'abstract'
            : 'open';
    indent.writeScoped(
      '$classModifier class $kotlinApiName(open val pigeonRegistrar: ${classNamePrefix}ProxyApiRegistrar) {',
      '}',
      () {
        final String fullKotlinClassName =
            api.kotlinOptions?.fullClassName ?? api.name;

        final TypeDeclaration apiAsTypeDeclaration = TypeDeclaration(
          baseName: api.name,
          isNullable: false,
          associatedProxyApi: api,
        );

        _writeProxyApiConstructorAbstractMethods(
          indent,
          api,
          apiAsTypeDeclaration: apiAsTypeDeclaration,
        );

        _writeProxyApiAttachedFieldAbstractMethods(
          indent,
          api,
          apiAsTypeDeclaration: apiAsTypeDeclaration,
        );

        if (api.hasCallbackConstructor()) {
          _writeProxyApiUnattachedFieldAbstractMethods(
            indent,
            api,
            apiAsTypeDeclaration: apiAsTypeDeclaration,
          );
        }

        _writeProxyApiHostMethodAbstractMethods(
          indent,
          api,
          apiAsTypeDeclaration: apiAsTypeDeclaration,
        );

        if (api.constructors.isNotEmpty ||
            api.attachedFields.isNotEmpty ||
            api.hostMethods.isNotEmpty) {
          indent.writeScoped('companion object {', '}', () {
            _writeProxyApiMessageHandlerMethod(
              indent,
              api,
              apiAsTypeDeclaration: apiAsTypeDeclaration,
              kotlinApiName: kotlinApiName,
              dartPackageName: dartPackageName,
              fullKotlinClassName: fullKotlinClassName,
            );
          });
          indent.newln();
        }

        _writeProxyApiNewInstanceMethod(
          indent,
          api,
          generatorOptions: generatorOptions,
          apiAsTypeDeclaration: apiAsTypeDeclaration,
          newInstanceMethodName: '${classMemberNamePrefix}newInstance',
          dartPackageName: dartPackageName,
        );

        _writeProxyApiFlutterMethods(
          indent,
          api,
          generatorOptions: generatorOptions,
          apiAsTypeDeclaration: apiAsTypeDeclaration,
          dartPackageName: dartPackageName,
        );

        _writeProxyApiInheritedApiMethods(indent, api);
      },
    );
  }

  /// Writes the codec class that will be used by [api].
  /// Example:
  /// private static class FooCodec extends StandardMessageCodec {...}
  void _writeCodec(Indent indent, Api api, Root root) {
    assert(getCodecClasses(api, root).isNotEmpty);
    final Iterable<EnumeratedClass> codecClasses = getCodecClasses(api, root);
    final String codecName = _getCodecName(api);
    indent.write('private object $codecName : StandardMessageCodec() ');
    indent.addScoped('{', '}', () {
      indent.write(
          'override fun readValueOfType(type: Byte, buffer: ByteBuffer): Any? ');
      indent.addScoped('{', '}', () {
        indent.write('return when (type) ');
        indent.addScoped('{', '}', () {
          for (final EnumeratedClass customClass in codecClasses) {
            indent.write('${customClass.enumeration}.toByte() -> ');
            indent.addScoped('{', '}', () {
              indent.write('return (readValue(buffer) as? List<Any?>)?.let ');
              indent.addScoped('{', '}', () {
                indent.writeln('${customClass.name}.fromList(it)');
              });
            });
          }
          indent.writeln('else -> super.readValueOfType(type, buffer)');
        });
      });

      indent.write(
          'override fun writeValue(stream: ByteArrayOutputStream, value: Any?) ');
      indent.writeScoped('{', '}', () {
        indent.write('when (value) ');
        indent.addScoped('{', '}', () {
          for (final EnumeratedClass customClass in codecClasses) {
            indent.write('is ${customClass.name} -> ');
            indent.addScoped('{', '}', () {
              indent.writeln('stream.write(${customClass.enumeration})');
              indent.writeln('writeValue(stream, value.toList())');
            });
          }
          indent.writeln('else -> super.writeValue(stream, value)');
        });
      });
    });
    indent.newln();
  }

  void _writeWrapResult(Indent indent) {
    indent.newln();
    indent.write('private fun wrapResult(result: Any?): List<Any?> ');
    indent.addScoped('{', '}', () {
      indent.writeln('return listOf(result)');
    });
  }

  void _writeWrapError(KotlinOptions generatorOptions, Indent indent) {
    indent.newln();
    indent.write('private fun wrapError(exception: Throwable): List<Any?> ');
    indent.addScoped('{', '}', () {
      indent.write(
          'return if (exception is ${_getErrorClassName(generatorOptions)}) ');
      indent.addScoped('{', '}', () {
        indent.writeScoped('listOf(', ')', () {
          indent.writeln('exception.code,');
          indent.writeln('exception.message,');
          indent.writeln('exception.details');
        });
      }, addTrailingNewline: false);
      indent.addScoped(' else {', '}', () {
        indent.writeScoped('listOf(', ')', () {
          indent.writeln('exception.javaClass.simpleName,');
          indent.writeln('exception.toString(),');
          indent.writeln(
              '"Cause: " + exception.cause + ", Stacktrace: " + Log.getStackTraceString(exception)');
        });
      });
    });
  }

  void _writeErrorClass(KotlinOptions generatorOptions, Indent indent) {
    indent.newln();
    indent.writeln('/**');
    indent.writeln(
        ' * Error class for passing custom error details to Flutter via a thrown PlatformException.');
    indent.writeln(' * @property code The error code.');
    indent.writeln(' * @property message The error message.');
    indent.writeln(
        ' * @property details The error details. Must be a datatype supported by the api codec.');
    indent.writeln(' */');
    indent.write('class ${_getErrorClassName(generatorOptions)} ');
    indent.addScoped('(', ')', () {
      indent.writeln('val code: String,');
      indent.writeln('override val message: String? = null,');
      indent.writeln('val details: Any? = null');
    }, addTrailingNewline: false);
    indent.addln(' : Throwable()');
  }

  void _writeCreateConnectionError(
      KotlinOptions generatorOptions, Indent indent) {
    final String errorClassName = _getErrorClassName(generatorOptions);
    indent.newln();
    indent.write(
        'private fun createConnectionError(channelName: String): $errorClassName ');
    indent.addScoped('{', '}', () {
      indent.write(
          'return $errorClassName("channel-error",  "Unable to establish connection on channel: \'\$channelName\'.", "")');
    });
  }

  @override
  void writeGeneralUtilities(
    KotlinOptions generatorOptions,
    Root root,
    Indent indent, {
    required String dartPackageName,
  }) {
    final bool hasHostApi = root.apis
        .whereType<AstHostApi>()
        .any((Api api) => api.methods.isNotEmpty);
    final bool hasFlutterApi = root.apis
        .whereType<AstFlutterApi>()
        .any((Api api) => api.methods.isNotEmpty);
    final bool hasProxyApi = root.apis.any((Api api) => api is AstProxyApi);

    if (hasHostApi || hasProxyApi) {
      _writeWrapResult(indent);
      _writeWrapError(generatorOptions, indent);
    }
    if (hasFlutterApi || hasProxyApi) {
      _writeCreateConnectionError(generatorOptions, indent);
    }
    if (generatorOptions.includeErrorClass) {
      _writeErrorClass(generatorOptions, indent);
    }
  }

  static void _writeMethodDeclaration(
    Indent indent, {
    required String name,
    required TypeDeclaration returnType,
    required List<Parameter> parameters,
    List<String> documentationComments = const <String>[],
    int? minApiRequirement,
    bool isAsynchronous = false,
    bool isOpen = false,
    bool isAbstract = false,
    String Function(int index, NamedType type) getArgumentName =
        _getArgumentName,
  }) {
    final List<String> argSignature = <String>[];
    if (parameters.isNotEmpty) {
      final Iterable<String> argTypes = parameters
          .map((NamedType e) => _nullSafeKotlinTypeForDartType(e.type));
      final Iterable<String> argNames = indexMap(parameters, getArgumentName);
      argSignature.addAll(
        map2(
          argTypes,
          argNames,
          (String argType, String argName) {
            return '$argName: $argType';
          },
        ),
      );
    }

    final String returnTypeString =
        returnType.isVoid ? '' : _nullSafeKotlinTypeForDartType(returnType);

    final String resultType = returnType.isVoid ? 'Unit' : returnTypeString;
    addDocumentationComments(indent, documentationComments, _docCommentSpec);

    if (minApiRequirement != null) {
      indent.writeln(
        '@androidx.annotation.RequiresApi(api = $minApiRequirement)',
      );
    }

    final String openKeyword = isOpen ? 'open ' : '';
    final String abstractKeyword = isAbstract ? 'abstract ' : '';

    if (isAsynchronous) {
      argSignature.add('callback: (Result<$resultType>) -> Unit');
      indent.writeln(
        '$openKeyword${abstractKeyword}fun $name(${argSignature.join(', ')})',
      );
    } else if (returnType.isVoid) {
      indent.writeln(
        '$openKeyword${abstractKeyword}fun $name(${argSignature.join(', ')})',
      );
    } else {
      indent.writeln(
        '$openKeyword${abstractKeyword}fun $name(${argSignature.join(', ')}): $returnTypeString',
      );
    }
  }

  void _writeHostMethodMessageHandler(
    Indent indent, {
    required String name,
    required String channelName,
    required TaskQueueType taskQueueType,
    required List<Parameter> parameters,
    required TypeDeclaration returnType,
    String setHandlerCondition = 'api != null',
    bool isAsynchronous = false,
    String Function(List<String> safeArgNames, {required String apiVarName})?
        onCreateCall,
  }) {
    indent.write('run ');
    indent.addScoped('{', '}', () {
      String? taskQueue;
      if (taskQueueType != TaskQueueType.serial) {
        taskQueue = 'taskQueue';
        indent.writeln(
            'val $taskQueue = binaryMessenger.makeBackgroundTaskQueue()');
      }

      indent.write(
        'val channel = BasicMessageChannel<Any?>(binaryMessenger, "$channelName", codec',
      );

      if (taskQueue != null) {
        indent.addln(', $taskQueue)');
      } else {
        indent.addln(')');
      }

      indent.write('if ($setHandlerCondition) ');
      indent.addScoped('{', '}', () {
        final String messageVarName = parameters.isNotEmpty ? 'message' : '_';

        indent.write('channel.setMessageHandler ');
        indent.addScoped('{ $messageVarName, reply ->', '}', () {
          final List<String> methodArguments = <String>[];
          if (parameters.isNotEmpty) {
            indent.writeln('val args = message as List<Any?>');
            enumerate(parameters, (int index, NamedType arg) {
              final String argName = _getSafeArgumentName(index, arg);
              final String argIndex = 'args[$index]';
              indent.writeln(
                  'val $argName = ${_castForceUnwrap(argIndex, arg.type, indent)}');
              methodArguments.add(argName);
            });
          }
          final String call = onCreateCall != null
              ? onCreateCall(methodArguments, apiVarName: 'api')
              : 'api.$name(${methodArguments.join(', ')})';

          if (isAsynchronous) {
            indent.write('$call ');
            final String resultType = returnType.isVoid
                ? 'Unit'
                : _nullSafeKotlinTypeForDartType(returnType);
            indent.addScoped('{ result: Result<$resultType> ->', '}', () {
              indent.writeln('val error = result.exceptionOrNull()');
              indent.writeScoped('if (error != null) {', '}', () {
                indent.writeln('reply.reply(wrapError(error))');
              }, addTrailingNewline: false);
              indent.addScoped(' else {', '}', () {
                final String enumTagNullablePrefix =
                    returnType.isNullable ? '?' : '!!';
                final String enumTag =
                    returnType.isEnum ? '$enumTagNullablePrefix.raw' : '';
                if (returnType.isVoid) {
                  indent.writeln('reply.reply(wrapResult(null))');
                } else {
                  indent.writeln('val data = result.getOrNull()');
                  indent.writeln('reply.reply(wrapResult(data$enumTag))');
                }
              });
            });
          } else {
            indent.writeScoped('val wrapped: List<Any?> = try {', '}', () {
              if (returnType.isVoid) {
                indent.writeln(call);
                indent.writeln('listOf<Any?>(null)');
              } else {
                String enumTag = '';
                if (returnType.isEnum) {
                  final String safeUnwrap = returnType.isNullable ? '?' : '';
                  enumTag = '$safeUnwrap.raw';
                }
                indent.writeln('listOf<Any?>($call$enumTag)');
              }
            }, addTrailingNewline: false);
            indent.add(' catch (exception: Throwable) ');
            indent.addScoped('{', '}', () {
              indent.writeln('wrapError(exception)');
            });
            indent.writeln('reply.reply(wrapped)');
          }
        });
      }, addTrailingNewline: false);
      indent.addScoped(' else {', '}', () {
        indent.writeln('channel.setMessageHandler(null)');
      });
    });
  }

  void _writeFlutterMethod(
    Indent indent, {
    required KotlinOptions generatorOptions,
    required String name,
    required List<Parameter> parameters,
    required TypeDeclaration returnType,
    required String channelName,
    required String dartPackageName,
    List<String> documentationComments = const <String>[],
    int? minApiRequirement,
    void Function(
      Indent indent, {
      required List<Parameter> parameters,
      required TypeDeclaration returnType,
      required String channelName,
      required String errorClassName,
    }) onWriteBody = _writeFlutterMethodMessageCall,
  }) {
    _writeMethodDeclaration(
      indent,
      name: name,
      returnType: returnType,
      parameters: parameters,
      documentationComments: documentationComments,
      isAsynchronous: true,
      minApiRequirement: minApiRequirement,
      getArgumentName: _getSafeArgumentName,
    );

    final String errorClassName = _getErrorClassName(generatorOptions);
    indent.addScoped('{', '}', () {
      onWriteBody(
        indent,
        parameters: parameters,
        returnType: returnType,
        channelName: channelName,
        errorClassName: errorClassName,
      );
    });
  }

  static void _writeFlutterMethodMessageCall(
    Indent indent, {
    required List<Parameter> parameters,
    required TypeDeclaration returnType,
    required String channelName,
    required String errorClassName,
  }) {
    String sendArgument;

    if (parameters.isEmpty) {
      sendArgument = 'null';
    } else {
      final Iterable<String> enumSafeArgNames = indexMap(
          parameters,
          (int count, NamedType type) =>
              _getEnumSafeArgumentExpression(count, type));
      sendArgument = 'listOf(${enumSafeArgNames.join(', ')})';
    }

    const String channel = 'channel';
    indent.writeln('val channelName = "$channelName"');
    indent.writeln(
        'val $channel = BasicMessageChannel<Any?>(binaryMessenger, channelName, codec)');
    indent.writeScoped('$channel.send($sendArgument) {', '}', () {
      indent.writeScoped('if (it is List<*>) {', '} ', () {
        indent.writeScoped('if (it.size > 1) {', '} ', () {
          indent.writeln(
              'callback(Result.failure($errorClassName(it[0] as String, it[1] as String, it[2] as String?)))');
        }, addTrailingNewline: false);
        if (!returnType.isNullable && !returnType.isVoid) {
          indent.addScoped('else if (it[0] == null) {', '} ', () {
            indent.writeln(
                'callback(Result.failure($errorClassName("null-error", "Flutter api returned null value for non-null return value.", "")))');
          }, addTrailingNewline: false);
        }
        indent.addScoped('else {', '}', () {
          if (returnType.isVoid) {
            indent.writeln('callback(Result.success(Unit))');
          } else {
            const String output = 'output';
            // Nullable enums require special handling.
            if (returnType.isEnum && returnType.isNullable) {
              indent.writeScoped(
                  'val $output = (it[0] as Int?)?.let { num ->', '}', () {
                indent.writeln('${returnType.baseName}.ofRaw(num)');
              });
            } else {
              indent.writeln(
                  'val $output = ${_cast(indent, 'it[0]', type: returnType)}');
            }
            indent.writeln('callback(Result.success($output))');
          }
        });
      }, addTrailingNewline: false);
      indent.addScoped('else {', '} ', () {
        indent.writeln(
            'callback(Result.failure(createConnectionError(channelName)))');
      });
    });
  }

  void _writeProxyApiRegistrar(
    Indent indent, {
    required Iterable<AstProxyApi> allProxyApis,
  }) {
    const String registrarName = '${classNamePrefix}ProxyApiRegistrar';
    const String instanceManagerApiName = '${instanceManagerClassName}Api';

    addDocumentationComments(
      indent,
      <String>[
        'Provides implementations for each ProxyApi implementation and provides access to resources',
        'needed by any implementation.',
      ],
      _docCommentSpec,
    );
    indent.writeScoped(
      'abstract class $registrarName(val binaryMessenger: BinaryMessenger) {',
      '}',
      () {
        indent.format(
          '''
          val instanceManager: $instanceManagerClassName
          private var _codec: StandardMessageCodec? = null
          val codec: StandardMessageCodec
            get() {
              if (_codec == null) {
                _codec = PigeonProxyApiBaseCodec(this)
              }
              return _codec!!
            }

          init {
            val api = $instanceManagerApiName(binaryMessenger)
            instanceManager = $instanceManagerClassName.create(
              object : $instanceManagerClassName.PigeonFinalizationListener {
                override fun onFinalize(identifier: Long) {
                  api.removeStrongReference(identifier) {
                    if (it.isFailure) {
                      Log.e(
                        "$registrarName",
                        "Failed to remove Dart strong reference with identifier: \$identifier"
                      )
                    }
                  }
                }
              }
            )
          }''',
          trimIndentation: true,
        );
        for (final AstProxyApi api in allProxyApis) {
          _writeMethodDeclaration(
            indent,
            name: 'get$hostProxyApiPrefix${api.name}',
            isAbstract:
                api.hasAnyHostMessageCalls() || api.unattachedFields.isNotEmpty,
            isOpen:
                !api.hasAnyHostMessageCalls() && api.unattachedFields.isEmpty,
            documentationComments: <String>[
              'An implementation of [$hostProxyApiPrefix${api.name}] used to add a new Dart instance of',
              '`${api.name}` to the Dart `InstanceManager`.'
            ],
            returnType: TypeDeclaration(
              baseName: '$hostProxyApiPrefix${api.name}',
              isNullable: false,
            ),
            parameters: <Parameter>[],
          );

          // Use the default API implementation if this API does not have any
          // methods to implement.
          if (!api.hasAnyHostMessageCalls() && api.unattachedFields.isEmpty) {
            indent.writeScoped('{', '}', () {
              indent.writeln('return $hostProxyApiPrefix${api.name}(this)');
            });
          }
          indent.newln();
        }

        indent.writeScoped('fun setUp() {', '}', () {
          indent.writeln(
            '$instanceManagerApiName.setUpMessageHandlers(binaryMessenger, instanceManager)',
          );
          for (final AstProxyApi api in allProxyApis) {
            final bool hasHostMessageCalls = api.constructors.isNotEmpty ||
                api.attachedFields.isNotEmpty ||
                api.hostMethods.isNotEmpty;
            if (hasHostMessageCalls) {
              indent.writeln(
                '$hostProxyApiPrefix${api.name}.setUpMessageHandlers(binaryMessenger, get$hostProxyApiPrefix${api.name}())',
              );
            }
          }
        });

        indent.writeScoped('fun tearDown() {', '}', () {
          indent.writeln(
            '$instanceManagerApiName.setUpMessageHandlers(binaryMessenger, null)',
          );
          for (final AstProxyApi api in allProxyApis) {
            if (api.hasAnyHostMessageCalls()) {
              indent.writeln(
                '$hostProxyApiPrefix${api.name}.setUpMessageHandlers(binaryMessenger, null)',
              );
            }
          }
        });
      },
    );
  }

  // Writes the abstract method that instantiates a new instance of the Kotlin
  // class.
  void _writeProxyApiConstructorAbstractMethods(
    Indent indent,
    AstProxyApi api, {
    required TypeDeclaration apiAsTypeDeclaration,
  }) {
    for (final Constructor constructor in api.constructors) {
      _writeMethodDeclaration(
        indent,
        name: constructor.name.isNotEmpty
            ? constructor.name
            : '${classMemberNamePrefix}defaultConstructor',
        returnType: apiAsTypeDeclaration,
        documentationComments: constructor.documentationComments,
        minApiRequirement: _findAndroidHighestApiRequirement(<TypeDeclaration>[
          apiAsTypeDeclaration,
          ...constructor.parameters.map(
            (Parameter parameter) => parameter.type,
          ),
        ])?.version,
        isAbstract: true,
        parameters: <Parameter>[
          ...api.unattachedFields.map((ApiField field) {
            return Parameter(name: field.name, type: field.type);
          }),
          ...constructor.parameters
        ],
      );
      indent.newln();
    }
  }

  // Writes the abstract method that handles instantiating an attached field.
  void _writeProxyApiAttachedFieldAbstractMethods(
    Indent indent,
    AstProxyApi api, {
    required TypeDeclaration apiAsTypeDeclaration,
  }) {
    for (final ApiField field in api.attachedFields) {
      _writeMethodDeclaration(
        indent,
        name: field.name,
        documentationComments: field.documentationComments,
        returnType: field.type,
        isAbstract: true,
        minApiRequirement: _findAndroidHighestApiRequirement(<TypeDeclaration>[
          apiAsTypeDeclaration,
          field.type,
        ])?.version,
        parameters: <Parameter>[
          if (!field.isStatic)
            Parameter(
              name: '${classMemberNamePrefix}instance',
              type: apiAsTypeDeclaration,
            ),
        ],
      );
      indent.newln();
    }
  }

  // Writes the abstract method that handles accessing an unattached field.
  void _writeProxyApiUnattachedFieldAbstractMethods(
    Indent indent,
    AstProxyApi api, {
    required TypeDeclaration apiAsTypeDeclaration,
  }) {
    for (final ApiField field in api.unattachedFields) {
      _writeMethodDeclaration(
        indent,
        name: field.name,
        documentationComments: field.documentationComments,
        returnType: field.type,
        isAbstract: true,
        minApiRequirement: _findAndroidHighestApiRequirement(<TypeDeclaration>[
          apiAsTypeDeclaration,
          field.type,
        ])?.version,
        parameters: <Parameter>[
          Parameter(
            name: '${classMemberNamePrefix}instance',
            type: apiAsTypeDeclaration,
          ),
        ],
      );
      indent.newln();
    }
  }

  // Writes the abstract method that handles making a call from for a host
  // method.
  void _writeProxyApiHostMethodAbstractMethods(
    Indent indent,
    AstProxyApi api, {
    required TypeDeclaration apiAsTypeDeclaration,
  }) {
    for (final Method method in api.hostMethods) {
      _writeMethodDeclaration(
        indent,
        name: method.name,
        returnType: method.returnType,
        documentationComments: method.documentationComments,
        isAsynchronous: method.isAsynchronous,
        isAbstract: true,
        minApiRequirement: _findAndroidHighestApiRequirement(
          <TypeDeclaration>[
            if (!method.isStatic) apiAsTypeDeclaration,
            method.returnType,
            ...method.parameters.map((Parameter p) => p.type),
          ],
        )?.version,
        parameters: <Parameter>[
          if (!method.isStatic)
            Parameter(
              name: '${classMemberNamePrefix}instance',
              type: apiAsTypeDeclaration,
            ),
          ...method.parameters,
        ],
      );
      indent.newln();
    }
  }

  // Writes the `..setUpMessageHandler` method to ensure incoming messages are
  // handled by the correct abstract host methods.
  void _writeProxyApiMessageHandlerMethod(
    Indent indent,
    AstProxyApi api, {
    required TypeDeclaration apiAsTypeDeclaration,
    required String kotlinApiName,
    required String dartPackageName,
    required String fullKotlinClassName,
  }) {
    indent.writeln('@Suppress("LocalVariableName")');
    indent.writeScoped(
      'fun setUpMessageHandlers(binaryMessenger: BinaryMessenger, api: $kotlinApiName?) {',
      '}',
      () {
        indent.writeln(
          'val codec = api?.pigeonRegistrar?.codec ?: StandardMessageCodec()',
        );
        void writeWithApiCheckIfNecessary(
          List<TypeDeclaration> types, {
          required String channelName,
          required void Function() onWrite,
        }) {
          final ({TypeDeclaration type, int version})? typeWithRequirement =
              _findAndroidHighestApiRequirement(types);
          if (typeWithRequirement != null) {
            final int apiRequirement = typeWithRequirement.version;
            indent.writeScoped(
              'if (android.os.Build.VERSION.SDK_INT >= $apiRequirement) {',
              '}',
              onWrite,
              addTrailingNewline: false,
            );
            indent.writeScoped(' else {', '}', () {
              final String className = typeWithRequirement
                      .type.associatedProxyApi!.kotlinOptions?.fullClassName ??
                  typeWithRequirement.type.baseName;
              indent.format(
                '''
                val channel = BasicMessageChannel<Any?>(
                  binaryMessenger,
                  "$channelName",
                  codec
                )
                if (api != null) {
                  channel.setMessageHandler { _, reply ->
                    reply.reply(wrapError(UnsupportedOperationException(
                      "Call references class `$className`, which requires api version $apiRequirement."
                    )))
                  }
                } else {
                  channel.setMessageHandler(null)
                }''',
                trimIndentation: true,
              );
            });
          } else {
            onWrite();
          }
        }

        for (final Constructor constructor in api.constructors) {
          final String name = constructor.name.isNotEmpty
              ? constructor.name
              : '${classMemberNamePrefix}defaultConstructor';
          final String channelName = makeChannelNameWithStrings(
            apiName: api.name,
            methodName: name,
            dartPackageName: dartPackageName,
          );
          writeWithApiCheckIfNecessary(
            <TypeDeclaration>[
              apiAsTypeDeclaration,
              ...api.unattachedFields.map((ApiField f) => f.type),
              ...constructor.parameters.map((Parameter p) => p.type),
            ],
            channelName: channelName,
            onWrite: () {
              _writeHostMethodMessageHandler(
                indent,
                name: name,
                channelName: channelName,
                taskQueueType: TaskQueueType.serial,
                returnType: const TypeDeclaration.voidDeclaration(),
                onCreateCall: (
                  List<String> methodParameters, {
                  required String apiVarName,
                }) {
                  return '$apiVarName.pigeonRegistrar.instanceManager.addDartCreatedInstance('
                      '$apiVarName.$name(${methodParameters.skip(1).join(',')}), ${methodParameters.first})';
                },
                parameters: <Parameter>[
                  Parameter(
                    name: '${classMemberNamePrefix}identifier',
                    type: const TypeDeclaration(
                      baseName: 'int',
                      isNullable: false,
                    ),
                  ),
                  ...api.unattachedFields.map((ApiField field) {
                    return Parameter(
                      name: field.name,
                      type: field.type,
                    );
                  }),
                  ...constructor.parameters,
                ],
              );
            },
          );
        }

        for (final ApiField field in api.attachedFields) {
          final String channelName = makeChannelNameWithStrings(
            apiName: api.name,
            methodName: field.name,
            dartPackageName: dartPackageName,
          );
          writeWithApiCheckIfNecessary(
            <TypeDeclaration>[apiAsTypeDeclaration, field.type],
            channelName: channelName,
            onWrite: () {
              _writeHostMethodMessageHandler(
                indent,
                name: field.name,
                channelName: channelName,
                taskQueueType: TaskQueueType.serial,
                returnType: const TypeDeclaration.voidDeclaration(),
                onCreateCall: (
                  List<String> methodParameters, {
                  required String apiVarName,
                }) {
                  final String param =
                      methodParameters.length > 1 ? methodParameters.first : '';
                  return '$apiVarName.pigeonRegistrar.instanceManager.addDartCreatedInstance('
                      '$apiVarName.${field.name}($param), ${methodParameters.last})';
                },
                parameters: <Parameter>[
                  if (!field.isStatic)
                    Parameter(
                      name: '${classMemberNamePrefix}instance',
                      type: apiAsTypeDeclaration,
                    ),
                  Parameter(
                    name: '${classMemberNamePrefix}identifier',
                    type: const TypeDeclaration(
                      baseName: 'int',
                      isNullable: false,
                    ),
                  ),
                ],
              );
            },
          );
        }

        for (final Method method in api.hostMethods) {
          final String channelName =
              makeChannelName(api, method, dartPackageName);
          writeWithApiCheckIfNecessary(
            <TypeDeclaration>[
              if (!method.isStatic) apiAsTypeDeclaration,
              method.returnType,
              ...method.parameters.map((Parameter p) => p.type),
            ],
            channelName: channelName,
            onWrite: () {
              _writeHostMethodMessageHandler(
                indent,
                name: method.name,
                channelName: makeChannelName(api, method, dartPackageName),
                taskQueueType: method.taskQueueType,
                returnType: method.returnType,
                isAsynchronous: method.isAsynchronous,
                parameters: <Parameter>[
                  if (!method.isStatic)
                    Parameter(
                      name: '${classMemberNamePrefix}instance',
                      type: TypeDeclaration(
                        baseName: fullKotlinClassName,
                        isNullable: false,
                        associatedProxyApi: api,
                      ),
                    ),
                  ...method.parameters,
                ],
              );
            },
          );
        }
      },
    );
  }

  // Writes the method that calls to Dart to instantiate a new Dart instance.
  void _writeProxyApiNewInstanceMethod(
    Indent indent,
    AstProxyApi api, {
    required KotlinOptions generatorOptions,
    required TypeDeclaration apiAsTypeDeclaration,
    required String newInstanceMethodName,
    required String dartPackageName,
  }) {
    indent.writeln('@Suppress("LocalVariableName", "FunctionName")');
    _writeFlutterMethod(
      indent,
      generatorOptions: generatorOptions,
      name: newInstanceMethodName,
      returnType: const TypeDeclaration.voidDeclaration(),
      documentationComments: <String>[
        'Creates a Dart instance of ${api.name} and attaches it to [${classMemberNamePrefix}instanceArg].',
      ],
      channelName: makeChannelNameWithStrings(
        apiName: api.name,
        methodName: newInstanceMethodName,
        dartPackageName: dartPackageName,
      ),
      minApiRequirement: _findAndroidHighestApiRequirement(<TypeDeclaration>[
        apiAsTypeDeclaration,
        ...api.unattachedFields.map((ApiField field) => field.type),
      ])?.version,
      dartPackageName: dartPackageName,
      parameters: <Parameter>[
        Parameter(
          name: '${classMemberNamePrefix}instance',
          type: TypeDeclaration(
            baseName: api.name,
            isNullable: false,
            associatedProxyApi: api,
          ),
        ),
      ],
      onWriteBody: (
        Indent indent, {
        required List<Parameter> parameters,
        required TypeDeclaration returnType,
        required String channelName,
        required String errorClassName,
      }) {
        indent.writeScoped(
          'if (pigeonRegistrar.instanceManager.containsInstance(${classMemberNamePrefix}instanceArg)) {',
          '}',
          () {
            indent.writeln('Result.success(Unit)');
            indent.writeln('return');
          },
        );
        if (api.hasCallbackConstructor()) {
          indent.writeln(
            'val ${classMemberNamePrefix}identifierArg = pigeonRegistrar.instanceManager.addHostCreatedInstance(${classMemberNamePrefix}instanceArg)',
          );
          enumerate(api.unattachedFields, (int index, ApiField field) {
            final String argName = _getSafeArgumentName(index, field);
            indent.writeln(
              'val $argName = ${field.name}(${classMemberNamePrefix}instanceArg)',
            );
          });

          indent
              .writeln('val binaryMessenger = pigeonRegistrar.binaryMessenger');
          indent.writeln('val codec = pigeonRegistrar.codec');
          _writeFlutterMethodMessageCall(
            indent,
            returnType: returnType,
            channelName: channelName,
            errorClassName: errorClassName,
            parameters: <Parameter>[
              Parameter(
                name: '${classMemberNamePrefix}identifier',
                type: const TypeDeclaration(
                  baseName: 'int',
                  isNullable: false,
                ),
              ),
              ...api.unattachedFields.map(
                (ApiField field) {
                  return Parameter(name: field.name, type: field.type);
                },
              ),
            ],
          );
        } else {
          indent.writeln(
            'throw IllegalStateException("Attempting to create a new Dart instance of ${api.name}, but the class has a nonnull callback method.")',
          );
        }
      },
    );
    indent.newln();
  }

  // Writes the Flutter methods that call back to Dart.
  void _writeProxyApiFlutterMethods(
    Indent indent,
    AstProxyApi api, {
    required KotlinOptions generatorOptions,
    required TypeDeclaration apiAsTypeDeclaration,
    required String dartPackageName,
  }) {
    for (final Method method in api.flutterMethods) {
      _writeFlutterMethod(
        indent,
        generatorOptions: generatorOptions,
        name: method.name,
        returnType: method.returnType,
        channelName: makeChannelName(api, method, dartPackageName),
        dartPackageName: dartPackageName,
        documentationComments: method.documentationComments,
        minApiRequirement: _findAndroidHighestApiRequirement(<TypeDeclaration>[
          apiAsTypeDeclaration,
          method.returnType,
          ...method.parameters.map((Parameter parameter) => parameter.type),
        ])?.version,
        parameters: <Parameter>[
          Parameter(
            name: '${classMemberNamePrefix}instance',
            type: TypeDeclaration(
              baseName: api.name,
              isNullable: false,
              associatedProxyApi: api,
            ),
          ),
          ...method.parameters,
        ],
        onWriteBody: (
          Indent indent, {
          required List<Parameter> parameters,
          required TypeDeclaration returnType,
          required String channelName,
          required String errorClassName,
        }) {
          indent
              .writeln('val binaryMessenger = pigeonRegistrar.binaryMessenger');
          indent.writeln('val codec = pigeonRegistrar.codec');
          _writeFlutterMethodMessageCall(
            indent,
            returnType: returnType,
            channelName: channelName,
            errorClassName: errorClassName,
            parameters: parameters,
          );
        },
      );
      indent.newln();
    }
  }

  // Writes the getters for accessing the implementation of other ProxyApis.
  //
  // These are used for inherited Flutter methods.
  void _writeProxyApiInheritedApiMethods(Indent indent, AstProxyApi api) {
    final Set<String> inheritedApiNames = <String>{
      if (api.superClass != null) api.superClass!.baseName,
      ...api.interfaces.map((TypeDeclaration type) => type.baseName),
    };
    for (final String name in inheritedApiNames) {
      indent.writeln('@Suppress("FunctionName")');
      final String apiName = '$hostProxyApiPrefix$name';
      _writeMethodDeclaration(
        indent,
        name: '${classMemberNamePrefix}get$apiName',
        documentationComments: <String>[
          'An implementation of [$apiName] used to access callback methods',
        ],
        returnType: TypeDeclaration(baseName: apiName, isNullable: false),
        parameters: <Parameter>[],
      );

      indent.writeScoped('{', '}', () {
        indent.writeln('return pigeonRegistrar.get$apiName()');
      });
      indent.newln();
    }
  }
}

({TypeDeclaration type, int version})? _findAndroidHighestApiRequirement(
  Iterable<TypeDeclaration> types,
) {
  return findHighestApiRequirement(
    types,
    onGetApiRequirement: (TypeDeclaration type) {
      return type.associatedProxyApi?.kotlinOptions?.minAndroidApi;
    },
    onCompare: (int first, int second) => first.compareTo(second),
  );
}

/// Calculates the name of the codec that will be generated for [api].
String _getCodecName(Api api) => '${api.name}Codec';

String _getErrorClassName(KotlinOptions generatorOptions) =>
    generatorOptions.errorClassName ?? 'FlutterError';

String _getArgumentName(int count, NamedType argument) =>
    argument.name.isEmpty ? 'arg$count' : argument.name;

/// Returns an argument name that can be used in a context where it is possible to collide
/// and append `.index` to enums.
String _getEnumSafeArgumentExpression(int count, NamedType argument) {
  if (argument.type.isEnum) {
    return argument.type.isNullable
        ? '${_getArgumentName(count, argument)}Arg?.raw'
        : '${_getArgumentName(count, argument)}Arg.raw';
  }
  return '${_getArgumentName(count, argument)}Arg';
}

/// Returns an argument name that can be used in a context where it is possible to collide.
String _getSafeArgumentName(int count, NamedType argument) =>
    '${_getArgumentName(count, argument)}Arg';

String _castForceUnwrap(String value, TypeDeclaration type, Indent indent) {
  if (type.isEnum) {
    final String forceUnwrap = type.isNullable ? '' : '!!';
    final String nullableConditionPrefix =
        type.isNullable ? 'if ($value == null) null else ' : '';
    return '$nullableConditionPrefix${_kotlinTypeForDartType(type)}.ofRaw($value as Int)$forceUnwrap';
  } else {
    return _cast(indent, value, type: type);
  }
}

/// Converts a [List] of [TypeDeclaration]s to a comma separated [String] to be
/// used in Kotlin code.
String _flattenTypeArguments(List<TypeDeclaration> args) {
  return args.map(_kotlinTypeForDartType).join(', ');
}

String _kotlinTypeForBuiltinGenericDartType(TypeDeclaration type) {
  if (type.typeArguments.isEmpty) {
    switch (type.baseName) {
      case 'List':
        return 'List<Any?>';
      case 'Map':
        return 'Map<Any, Any?>';
      default:
        return 'Any';
    }
  } else {
    switch (type.baseName) {
      case 'List':
        return 'List<${_nullSafeKotlinTypeForDartType(type.typeArguments.first)}>';
      case 'Map':
        return 'Map<${_nullSafeKotlinTypeForDartType(type.typeArguments.first)}, ${_nullSafeKotlinTypeForDartType(type.typeArguments.last)}>';
      default:
        return '${type.baseName}<${_flattenTypeArguments(type.typeArguments)}>';
    }
  }
}

String? _kotlinTypeForBuiltinDartType(TypeDeclaration type) {
  const Map<String, String> kotlinTypeForDartTypeMap = <String, String>{
    'void': 'Void',
    'bool': 'Boolean',
    'String': 'String',
    'int': 'Long',
    'double': 'Double',
    'Uint8List': 'ByteArray',
    'Int32List': 'IntArray',
    'Int64List': 'LongArray',
    'Float32List': 'FloatArray',
    'Float64List': 'DoubleArray',
    'Object': 'Any',
  };
  if (kotlinTypeForDartTypeMap.containsKey(type.baseName)) {
    return kotlinTypeForDartTypeMap[type.baseName];
  } else if (type.baseName == 'List' || type.baseName == 'Map') {
    return _kotlinTypeForBuiltinGenericDartType(type);
  } else {
    return null;
  }
}

String? _kotlinTypeForProxyApiType(TypeDeclaration type) {
  if (type.isProxyApi) {
    return type.associatedProxyApi!.kotlinOptions?.fullClassName ??
        type.associatedProxyApi!.name;
  }

  return null;
}

String _kotlinTypeForDartType(TypeDeclaration type) {
  return _kotlinTypeForBuiltinDartType(type) ??
      _kotlinTypeForProxyApiType(type) ??
      type.baseName;
}

String _nullSafeKotlinTypeForDartType(TypeDeclaration type) {
  final String nullSafe = type.isNullable ? '?' : '';
  return '${_kotlinTypeForDartType(type)}$nullSafe';
}

/// Returns an expression to cast [variable] to [kotlinType].
String _cast(Indent indent, String variable, {required TypeDeclaration type}) {
  // Special-case Any, since no-op casts cause warnings.
  final String typeString = _kotlinTypeForDartType(type);
  if (type.isNullable && typeString == 'Any') {
    return variable;
  }
  if (typeString == 'Int' || typeString == 'Long') {
    return '$variable${_castInt(type.isNullable)}';
  }
  if (type.isEnum) {
    if (type.isNullable) {
      return '($variable as Int?)?.let { num ->\n'
          '${indent.str}  $typeString.ofRaw(num)\n'
          '${indent.str}}';
    }
    return '${type.baseName}.ofRaw($variable as Int)!!';
  }
  return '$variable as ${_nullSafeKotlinTypeForDartType(type)}';
}

String _castInt(bool isNullable) {
  final String nullability = isNullable ? '?' : '';
  return '.let { num -> if (num is Int) num.toLong() else num as Long$nullability }';
}
