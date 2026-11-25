"""Consolida un único conjunto de JUnit XML por ejecución, sin fabricar resultados."""
import argparse
import json
import sys
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path


def leer_junit(archivos):
    casos, vistos = [], set()
    for archivo in archivos:
        raiz = ET.parse(archivo).getroot()
        # Algunos runners registran fallos de arranque a nivel de suite, sin testcase.
        for suite in raiz.iter():
            if suite.tag not in ('testsuite', 'testsuites'):
                continue
            for atributo, etiqueta in [('failures', 'failure'), ('errors', 'error')]:
                declarados = int(suite.get(atributo, '0'))
                observados = sum(c.find(etiqueta) is not None for c in suite.iter('testcase'))
                if declarados > observados:
                    raise ValueError(f'{archivo.name}: {atributo} de suite sin caso asociado; revisar el runner')
        for caso in raiz.iter('testcase'):
            identidad = (caso.get('classname', ''), caso.get('name', ''))
            if identidad in vistos:
                raise ValueError(f'Caso duplicado {identidad}; no mezclar runs ni suite completa con su subconjunto')
            vistos.add(identidad)
            casos.append({
                'clase': identidad[0], 'nombre': identidad[1],
                'segundos': float(caso.get('time', '0')),
                'fallo': caso.find('failure') is not None,
                'error': caso.find('error') is not None,
                'omitido': caso.find('skipped') is not None,
            })
    return casos


def resumir(casos):
    fallos = sum(c['fallo'] for c in casos)
    errores = sum(c['error'] for c in casos)
    omitidos = sum(c['omitido'] for c in casos)
    return {'casos': len(casos), 'fallos': fallos, 'errores': errores,
            'omitidos': omitidos, 'segundos': sum(c['segundos'] for c in casos),
            'aprobado': len(casos) > omitidos and fallos == 0 and errores == 0}


def principal():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--junit', type=Path, required=True, help='Un archivo o directorio JUnit de un solo run')
    parser.add_argument('--etiqueta', required=True, help='Ejemplo: backend-integracion-h2')
    parser.add_argument('--sha', required=True, help='SHA del código probado, tomado del run original')
    parser.add_argument('--salida', type=Path, required=True)
    args = parser.parse_args()
    archivos = sorted(args.junit.glob('*.xml')) if args.junit.is_dir() else [args.junit]
    if not archivos or any(not f.is_file() for f in archivos):
        print('Faltan reportes JUnit: ejecución NO VERIFICADA', file=sys.stderr)
        return 2
    try:
        casos = leer_junit(archivos)
    except (ET.ParseError, ValueError, OSError) as error:
        print(f'Evidencia inválida: {error}', file=sys.stderr)
        return 2
    resumen = resumir(casos)
    datos = {'fechaConsolidacionUTC': datetime.now(timezone.utc).isoformat(),
             'etiqueta': args.etiqueta, 'shaDeclarado': args.sha,
             'resumen': resumen, 'casos': casos}
    args.salida.mkdir(parents=True, exist_ok=True)
    (args.salida / 'resumen.json').write_text(json.dumps(datos, indent=2, ensure_ascii=False), encoding='utf-8')
    lineas = [f'# Evidencia: {args.etiqueta}', '', f'SHA declarado del run: `{args.sha}`.', '',
              f"Resultado: {'PASA' if resumen['aprobado'] else 'NO APRUEBA'}. Casos: {len(casos)}; "
              f"fallos: {resumen['fallos']}; errores: {resumen['errores']}; omitidos: {resumen['omitidos']}.", '',
              '| Clase/archivo | Casos | Fallos | Errores | Omitidos |', '|---|---:|---:|---:|---:|']
    for clase in sorted({c['clase'] for c in casos}):
        grupo = resumir([c for c in casos if c['clase'] == clase])
        lineas.append(f"| {clase.replace('|', '/')} | {grupo['casos']} | {grupo['fallos']} | {grupo['errores']} | {grupo['omitidos']} |")
    lineas += ['', 'Consolidación de resultados existentes; no ejecuta pruebas ni mide cobertura. '
               'No sumar este subconjunto a la suite completa. Validar SHA, fecha y artefacto originales.']
    (args.salida / 'resumen.md').write_text('\n'.join(lineas) + '\n', encoding='utf-8')
    return 0 if resumen['aprobado'] else 1


if __name__ == '__main__':
    raise SystemExit(principal())
