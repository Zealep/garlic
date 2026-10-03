import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../domain/models/compra.dart';
import '../../../../../domain/use_cases/calculo_compra.dart';
import '../../../../../utils/formato.dart';
import '../../../../core/theme/colores.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/widgets/componentes.dart';
import '../../view_models/compra_view_model.dart';

/// Color del estado de pago (verde pagado, ámbar pendiente, rojo pagado de más).
Color colorEstadoPago(EstadoPago e) => switch (e) {
  EstadoPago.sinCompras => GColores.tintaSuave,
  EstadoPago.porPagar => GColores.advertencia,
  EstadoPago.parcial => GColores.acento,
  EstadoPago.pagado => GColores.exito,
  EstadoPago.pagadoDeMas => GColores.error,
};

/// Balance de pago y costos (3.4 a 3.6 del protocolo).
class BalanceCompraPanel extends StatelessWidget {
  const BalanceCompraPanel({super.key, required this.vm});

  final CompraViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final b = vm.balance;
    final blanco = Colors.white.withValues(alpha: .8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(GEspacio.xl),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [GColores.primario, GColores.primarioProfundo]),
            borderRadius: BorderRadius.circular(GRadio.tarjeta),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Saldo por pagar', style: t.labelLarge!.copyWith(color: GColores.acento))),
                  _PastillaEstado(estado: b.estadoPago),
                ],
              ),
              const SizedBox(height: GEspacio.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(Formato.soles(b.saldo), style: GTipo.cifra(36, color: Colors.white)),
              ),
              const SizedBox(height: GEspacio.m),
              Row(
                children: [
                  Expanded(child: _Cifra('Total materia prima', Formato.soles(b.totalMp), blanco)),
                  Expanded(child: _Cifra('Pagado', Formato.soles(b.totalPagado), blanco)),
                ],
              ),
              if (b.totalMp > 0) ...[
                const SizedBox(height: GEspacio.m),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (b.totalPagado / b.totalMp).clamp(0, 1).toDouble(),
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: .15),
                    color: b.estadoPago == EstadoPago.pagadoDeMas ? GColores.errorSuave : GColores.acento,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: GEspacio.m),
        SeccionTarjeta(
          titulo: 'Puesto en packing',
          icono: PhosphorIconsBold.warehouse,
          child: Column(
            children: [
              _Fila('Kg cargados', Formato.kg(b.kgCargados)),
              _Fila('Destare', '− ${Formato.kg(b.destareKg)}'),
              _Fila('Kg netos', Formato.kg(b.kgNetos), fuerte: true),
              const Divider(height: GEspacio.xl),
              _Fila('Materia prima', Formato.soles(b.totalMp)),
              _Fila('Gastos vinculados', Formato.soles(b.gastosVinculados)),
              _Fila('Total puesto en packing', Formato.soles(b.costoPacking), fuerte: true),
              const Divider(height: GEspacio.xl),
              _Fila('C.U. materia prima', b.cuMp == null ? '—' : '${Formato.precioKg(b.cuMp)} /kg'),
              _Fila(
                'C.U. puesto en packing',
                b.cuPacking == null ? '—' : '${Formato.precioKg(b.cuPacking)} /kg',
                fuerte: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tarjeta del detalle del lote: precio pactado, kg netos y saldo.
class ResumenCompraTarjeta extends StatelessWidget {
  const ResumenCompraTarjeta({super.key, required this.compra, required this.onTap, this.editable = true});

  final CompraLote? compra;
  final VoidCallback onTap;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = compra;
    final b = c?.balance;
    final pactado = c?.fijacion?.precioPactado;
    return SeccionTarjeta(
      titulo: 'Compra y pagos',
      icono: PhosphorIconsBold.handCoins,
      accion: b == null || c!.vacia ? null : _PastillaEstado(estado: b.estadoPago, claro: true),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GRadio.chico),
        child:
            c == null || c.vacia
                ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: GEspacio.s),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Fija el precio con la evaluación cerrada, registra cada camión, los gastos y los pagos.',
                          style: t.bodySmall,
                        ),
                      ),
                      const SizedBox(width: GEspacio.m),
                      FilledButton.tonalIcon(
                        onPressed: onTap,
                        icon: Icon(editable ? PhosphorIconsBold.currencyCircleDollar : PhosphorIconsBold.eye),
                        label: Text(editable ? 'Fijar precio' : 'Ver'),
                      ),
                    ],
                  ),
                )
                : Row(
                  children: [
                    Expanded(
                      child: _Mini(
                        'Precio pactado',
                        pactado == null ? 'Sin pactar' : '${Formato.precioKg(pactado)}/kg',
                      ),
                    ),
                    Expanded(child: _Mini('Kg netos', Formato.kg(b!.kgNetos))),
                    Expanded(child: _Mini('Saldo', Formato.soles(b.saldo), color: colorEstadoPago(b.estadoPago))),
                    const Icon(PhosphorIconsBold.caretRight, color: GColores.tintaSuave),
                  ],
                ),
      ),
    );
  }
}

class _PastillaEstado extends StatelessWidget {
  const _PastillaEstado({required this.estado, this.claro = false});

  final EstadoPago estado;
  final bool claro;

  @override
  Widget build(BuildContext context) {
    final color = colorEstadoPago(estado);
    return claro
        ? Pastilla(texto: estado.etiqueta, color: color)
        : Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
          child: Text(estado.etiqueta, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra(this.etiqueta, this.valor, this.color);

  final String etiqueta;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(etiqueta, style: TextStyle(color: color, fontSize: 12)),
      Text(valor, style: GTipo.cifra(16, color: Colors.white)),
    ],
  );
}

class _Fila extends StatelessWidget {
  const _Fila(this.etiqueta, this.valor, {this.fuerte = false});

  final String etiqueta;
  final String valor;
  final bool fuerte;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta, style: fuerte ? t.titleSmall : t.bodyMedium)),
          Text(
            valor,
            style: GTipo.cifra(
              fuerte ? 15 : 14,
              color: fuerte ? GColores.primario : GColores.tinta,
              weight: fuerte ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.etiqueta, this.valor, {this.color = GColores.tinta});

  final String etiqueta;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: t.bodySmall),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(valor, style: GTipo.cifra(15, color: color)),
        ),
      ],
    );
  }
}
