"""Valida exportaciones de Guillermo; no ejecuta Retail ni certifica otra revisión Git."""
import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path
import re
import sys


def exigir(condicion, mensaje):
    if not condicion:
        raise ValueError(mensaje)


def natural(valor):
    return isinstance(valor, int) and not isinstance(valor, bool) and valor >= 0


def revisar_backend(suites):
    exigir(bool(suites), 'Backend sin suites')
    identidades, clases, tipos = set(), set(), Counter()
    for suite in suites:
        exigir(suite['clase'] not in clases, 'Clase backend duplicada')
        clases.add(suite['clase'])
        exigir(suite['cantidad'] == len(suite['casos']), 'Cantidad backend no coincide con casos')
        exigir(bool(suite['casos']), 'Suite backend sin casos')
        for caso in suite['casos']:
            identidad = (suite['clase'], caso['grupo'], caso['nombre'])
            exigir(identidad not in identidades, 'Caso backend duplicado')
            exigir(caso['estado'] == 'aprobado', 'Caso backend no aprobado')
            identidades.add(identidad)
            tipos[caso['tipo']] += 1
    return {'clases': len(clases), 'casos': len(identidades), 'por_tipo': dict(sorted(tipos.items()))}


def revisar_frontend(reporte):
    exigir(reporte['success'] is True, 'Vitest indica fallo global')
    identidades, archivos = set(), set()
    for suite in reporte['testResults']:
        exigir(suite['name'] not in archivos, 'Archivo frontend duplicado')
        archivos.add(suite['name'])
        exigir(suite['status'] == 'passed' and bool(suite['assertionResults']), 'Suite frontend no aprobada o vacía')
        for caso in suite['assertionResults']:
            identidad = (suite['name'], caso['fullName'])
            exigir(identidad not in identidades, 'Caso frontend duplicado')
            exigir(caso['status'] == 'passed' and not caso.get('failureMessages'), 'Caso frontend no aprobado')
            identidades.add(identidad)
    cantidad = len(identidades)
    exigir(cantidad > 0, 'Frontend sin casos')
    exigir(reporte['numTotalTests'] == reporte['numPassedTests'] == cantidad, 'Totales Vitest inconsistentes')
    exigir(reporte['numFailedTests'] == reporte['numPendingTests'] == 0, 'Vitest declara fallos u omitidos')
    return {'archivos': len(archivos), 'casos': cantidad}


def revisar_cobertura_backend(datos):
    resultado = {}
    exigir(bool(datos['metricas']) and bool(datos['paquetes']), 'Cobertura backend vacía')
    nombres = [p['paquete'] for p in datos['paquetes']]
    exigir(len(nombres) == len(set(nombres)), 'Paquete duplicado')
    for contador in datos['metricas']:
        tipo = contador['tipo']
        exigir(tipo not in resultado, 'Contador JaCoCo duplicado')
        for campo in ['cubiertos', 'noCubiertos']:
            exigir(natural(contador[campo]), 'Contador JaCoCo inválido')
            valores = []
            for paquete in datos['paquetes']:
                contadores = [m for m in paquete['metricas'] if m['tipo'] == tipo]
                exigir(len(contadores) <= 1, 'Contador de paquete duplicado')
                # JaCoCo omite un tipo de contador cuando el paquete no tiene elementos.
                valores.append(contadores[0][campo] if contadores else 0)
            exigir(all(natural(v) for v in valores), 'Contadores de paquete inválidos')
            exigir(sum(valores) == contador[campo], 'Total JaCoCo no coincide con paquetes')
        total = contador['cubiertos'] + contador['noCubiertos']
        resultado[tipo] = {**contador, 'total': total,
                           'porcentaje': round(100 * contador['cubiertos'] / total, 2) if total else None}
    return resultado


def revisar_cobertura_frontend(datos):
    exigir('total' in datos and len(datos) > 1, 'Cobertura frontend vacía')
    for metrica in ['lines', 'branches', 'functions', 'statements']:
        for nombre, valores in datos.items():
            c = valores[metrica]
            exigir(natural(c['total']) and natural(c['covered']) and c['covered'] <= c['total'], 'Contador V8 inválido')
            exigir(isinstance(c['pct'], (int, float)) and math.isfinite(c['pct']), 'Porcentaje V8 inválido')
            if c['total']:
                # Istanbul trunca a dos decimales; no exigir redondeo al valor superior.
                exigir(abs(c['pct'] - c['covered'] * 100 / c['total']) <= 0.011, 'Porcentaje V8 inconsistente')
        for campo in ['total', 'covered']:
            exigir(sum(v[metrica][campo] for k, v in datos.items() if k != 'total') == datos['total'][metrica][campo],
                   'Total V8 no coincide con archivos')
    return datos['total']


def revisar(carpeta, informe):
    cargar = lambda nombre: json.loads((carpeta / nombre).read_text(encoding='utf-8-sig'))
    backend = revisar_backend(cargar('backend-resultados.json'))
    frontend = revisar_frontend(cargar('frontend-resultados.json'))
    bc = revisar_cobertura_backend(cargar('backend-cobertura.json'))
    fc = revisar_cobertura_frontend(cargar('frontend-cobertura.json'))
    contenido = informe.read_text(encoding='utf-8-sig')
    conteos = re.search(r'\| Casos aprobados \| (\d+) \| (\d+) \|', contenido)
    exigir(conteos is not None, 'El informe no declara el total de casos')
    exigir([int(v) for v in conteos.groups()] == [backend['casos'], frontend['casos']], 'El informe discrepa de los JSON')
    for etiqueta, b, f in [('líneas', bc['LINE']['porcentaje'], fc['lines']['pct']),
                           ('ramas', bc['BRANCH']['porcentaje'], fc['branches']['pct'])]:
        valores = re.search(rf'\| Cobertura de {etiqueta}, suite completa \| ([\d.]+)%.*?\| ([\d.]+)%', contenido)
        exigir(valores is not None and all(abs(float(v) - n) < 0.011 for v, n in zip(valores.groups(), [b, f])),
               f'Cobertura de {etiqueta} del informe inconsistente')
    rf = sorted(set(re.findall(r'^\| RF-(\d{2}) \|', contenido, re.MULTILINE)))
    exigir(rf == [f'{n:02d}' for n in range(1, 29)], 'La matriz no tiene RF-01 a RF-28')
    archivos = [informe] + sorted(carpeta.iterdir())
    exigir(all(f.is_file() for f in archivos), 'La entrega contiene entradas inesperadas')
    huellas = [{'archivo': f.name if f == informe else f'evidencias-s14/{f.name}',
                'bytes': f.stat().st_size, 'sha256': hashlib.sha256(f.read_bytes()).hexdigest()} for f in archivos]
    return {'fechaRevisionUTC': datetime.now(timezone.utc).isoformat(),
            'resultado': 'CONSISTENTE_CON_LOS_ARCHIVOS_ENTREGADOS',
            'alcance': 'Revisión documental y aritmética; no es reejecución ni certificación del código actual',
            'backend': backend, 'frontend': frontend, 'coberturaBackend': bc, 'coberturaFrontend': fc,
            'rfEnMatriz': len(rf), 'archivos': huellas}


def principal():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--carpeta', type=Path, required=True)
    parser.add_argument('--informe', type=Path, required=True)
    parser.add_argument('--salida', type=Path, required=True)
    args = parser.parse_args()
    try:
        resultado = revisar(args.carpeta, args.informe)
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f'No se puede validar la entrega: {error}', file=sys.stderr)
        return 1
    args.salida.parent.mkdir(parents=True, exist_ok=True)
    args.salida.write_text(json.dumps(resultado, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f"Entrega consistente: {resultado['backend']['casos']} casos backend y {resultado['frontend']['casos']} frontend")
    return 0


if __name__ == '__main__':
    raise SystemExit(principal())
