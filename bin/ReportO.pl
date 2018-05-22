#!/usr/bin/perl
use Data::Dumper;
use Time::Piece;
use Time::Seconds;

use constant NOMBRE_VARIABLE_RUTA_ABSOLUTA_GRUPO02    => "GRUPO02";
use constant NOMBRE_VARIABLE_RUTA_RELATIVA_LIBRERIAS  => "LIBDIR";
use constant NOMBRE_VARIABLE_RUTA_RELATIVA_MAESTROS   => "MASTERDIR";
use constant NOMBRE_VARIABLE_RUTA_RELATIVA_PROCESADOS => "PROCESSEDDIR";
use constant NOMBRE_VARIABLE_RUTA_RELATIVA_REPORTES   => "REPORTDIR";

use constant NOMBRE_ARCHIVO_SCRIPT_INICIALIZADO => "inicializado?.sh";
use constant NOMBRE_ARCHIVO_MAESTRO_PRESTAMOS   => "PPI.mae";
use constant NOMBRE_ARCHIVO_PRESTAMOS => "PRESTAMOS";
use constant NOMBRE_ARCHIVO_COMPARADO => "comparado";
use constant NRO_CAMPOS_MAESTRO => 14;
use constant NRO_CAMPOS_PRESTAMOS => 16;
use constant NRO_CAMPOS_COMPARATIVA => 13;

use constant CANTIDAD_DE_CICLOS => 3; #Cantidad máxima de consultas que puede hacer el usuario.
use constant LIMITE_DE_CICLOS_BYPASSEADOS => 1; #"0" -> Apagado el bypass, "1" -> habilitado el bypass.
use constant AUN_NO => "AUN NO"; #Utilizada en iteraciones que requieren que el usuario ingrese un valor con un formato específico.
use constant CODIGO_PAIS => "codigo_pais";
use constant CODIGO_SISTEMA => "codigo_sistema";
use constant FECHA_DESDE => "fecha_desde";
use constant FECHA_HASTA => "fecha_hasta";
use constant PORCENTAJE => "porcentaje";
use constant VALOR_ABSOLUTO => "valor_absoluto";


{
  if(! verificar_ambiente()) {
    print "Ambiente incorrecto.\n";
    exit 1;
  }
  if(! preparar_ambiente_local()) {
    print "No se puede acceder a los archivos necesarios.\n";
    exit 1;
  }
  mostrar_menu_bienvenida();
  mostrar_menu_de_consultas();
  $nro_de_ciclo = 0;
  while((LIMITE_DE_CICLOS_BYPASSEADOS || ($nro_de_ciclo++ < CANTIDAD_DE_CICLOS)) &&
         (@consulta = recibir_consulta())) {
    if(validar_consulta_e_informar_errores(@consulta)) {
      procesar_consulta(@consulta);
    }
    print "Presione la tecla \"enter\" para realizar una nueva consulta o salir del programa.\n";
    <STDIN>; #TODO(Iván): quitar esta línea.
    system("clear");
    mostrar_menu_de_consultas();
  }
  exit 0;
}

sub fecha_en_intervalo {
  my($fecha_desde, $fecha_hasta, $fecha_prestamo) = ($_[0], $_[1], $_[2]);
  if($fecha_desde eq '') {
    if($fecha_hasta eq '') {
      return 1;
    } else {
      if($$fecha_hasta >= $$fecha_prestamo) {
        return 1;
      } else {
        return 0;
      }
    }
  } else {
    if($$fecha_desde <= $$fecha_prestamo) {
      if($fecha_hasta eq '') {
        return 1;
      } else {
        if($$fecha_hasta >= $$fecha_prestamo) {
          return 1;
        } else {
          return 0;
        }
      }
    } else {
      return 0;
    }
  }
}

sub procesar_divergencia_absoluta {
  my($comando, $ref_parametros, $opcion_grabar) = ($_[0], $_[1], $_[2]);
  my($user_pais_id, $user_sistema_id) = ($$ref_parametros{CODIGO_PAIS()}, $$ref_parametros{CODIGO_SISTEMA()});
  my($fecha_desde, $fecha_hasta) = ($$ref_parametros{FECHA_DESDE()}, $$ref_parametros{FECHA_HASTA()});
  my($valor_absoluto) = $$ref_parametros{VALOR_ABSOLUTO()};
  if($user_sistema_id eq "") {
    $user_sistema_id = '\d+';
  }
  my($ref_comparativa) = cargar_comparativa($user_pais_id, $user_sistema_id, $fecha_desde, $fecha_hasta);
  my(@resultados);
  foreach my $sistema_id (keys(%$ref_comparativa)) {
    foreach my $prestamo_id (keys(%{$ref_comparativa->{$sistema_id}})) {
      my($mt_rest_maestro) = $ref_comparativa->{$sistema_id}->{$prestamo_id}->{"mt_rest_maestro"};
      my($mt_rest_prestamos) = $ref_comparativa->{$sistema_id}->{$prestamo_id}->{"mt_rest_prestamos"};
      my($diferencia_absoluta) = abs($mt_rest_maestro - $mt_rest_prestamos);
      my($diferencia_porcentual_absoluta) = ($diferencia_absoluta / $mt_rest_maestro) * 100;
      my($listar) = "no se lista";
      if($diferencia_absoluta > $valor_absoluto) {
        $listar = "se lista";
      }
      my(@salida) = ($user_pais_id, $sistema_id, $prestamo_id, $listar, $mt_rest_maestro, $mt_rest_prestamos, $diferencia_absoluta, $diferencia_porcentual_absoluta);
      push(@resultados, \@salida);
    }
  }
  procesar_resultados_divergencia(\@resultados, $opcion_grabar);
  return @resultados;
}

sub procesar_resultados_divergencia{
  my($ref_resultados, $grabar) = ($_[0], $_[1]);
  print "┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐\n";
  print "│ Cod. País │ Cod. Sist. │  Cod. Prest.  │  RECOMEND.  │ Monto Rest. M │ Monto Rest. P. │ Diferencia abs. (M-P) │ Diferencia % (M-P) │\n";
  print "├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤\n";
  foreach my $resultado (@$ref_resultados) {
    $$resultado[6] = sprintf("%.2f", $$resultado[6]);
    $$resultado[6] =~ s/\./,/;
    $$resultado[7] = sprintf("%.0f", $$resultado[7]);
    $$resultado[7] =~ s/\./,/;
    if($grabar eq "GRABAR") {
      my($linea) = join(";", @$resultado);
      print REPORTE_D "$linea\n";
    }
  open STDOUT2, ">-" or die "Error: $!\n";
  format STDOUT2 =
│ @|||||||| │ @||||||||| │ @>>>>>>>>>>>> │ @>>>>>>>>>> │ @>>>>>>>>>>>> │ @>>>>>>>>>>>>> │ @>>>>>>>>>>>>>>>>>>>> │ @>>>>>>>>>>>>>>>>> │
  @$resultado
.
  write STDOUT2;
  }
  my($lineas) = @$ref_resultados;
  if($lineas == 0) {
    print "│-----------------------------------------------------------no hay datos-------------------------------------------------------------│\n";
  }
  print "└────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘\n";
  close(REPORTE_D);
}

sub cargar_comparativa {
  my($user_pais_id, $user_sistema_id) = ($_[0], $_[1]);
  my($fecha_desde, $fecha_hasta) = ($_[2], $_[3]);
  my($un_prestamo, $sistema_id, $prestamo_id, @campos, @claves, %prestamo, %todos_los_prestamos);
  while($un_prestamo = <COMPARATIVA>) {
    if($un_prestamo =~ /^$user_pais_id;$user_sistema_id;.*/) {
      $un_prestamo =~ s/\r?\n$//;
      @campos = split(";", $un_prestamo);
      if(@campos != NRO_CAMPOS_COMPARATIVA()) {
        print "Registro mal formado en el archivo de comparativas:\n";
        print "$un_prestamo\n";
      } else {
        @claves = ("pres_id", "recomendacion", "ctb_estado_maestro", "ctb_estado_prestamos", "mt_rest_maestro", "mt_rest_prestamos", "diferencia", "ctb_anio", "ctb_mes", "ctb_dia", "ctb_dia_prestamos");
        shift(@campos);
        $sistema_id = shift(@campos);
        my(%prestamo);
        @prestamo{@claves} = @campos;
        my($fecha_prestamo) = Time::Piece->strptime($prestamo{"ctb_anio"}." ".$prestamo{"ctb_mes"}." ".$prestamo{"ctb_dia"}, "%Y %m %d");
        if(fecha_en_intervalo($fecha_desde, $fecha_hasta, \$fecha_prestamo)) {
          $prestamo_id = $prestamo{"pres_id"};
          delete @prestamo{"pres_id", "recomendacion", "ctb_estado_maestro", "ctb_estado_prestamos", "diferencia", "ctb_anio", "ctb_mes", "ctb_dia", "ctb_dia_prestamos"};
          $todos_los_prestamos{$sistema_id}{$prestamo_id} = \%prestamo;
          #$todos_los_prestamos{$sistema_id}{$prestamo_id} = {%prestamo};
        }
      }
    }
  }
  close(MAESTRO);
  return \%todos_los_prestamos;
}

sub procesar_divergencia_porcentual {
  my($comando, $ref_parametros, $opcion_grabar) = ($_[0], $_[1], $_[2]);
  my($user_pais_id, $user_sistema_id) = ($$ref_parametros{CODIGO_PAIS()}, $$ref_parametros{CODIGO_SISTEMA()});
  my($fecha_desde, $fecha_hasta) = ($$ref_parametros{FECHA_DESDE()}, $$ref_parametros{FECHA_HASTA()});
  my($porcentaje) = $$ref_parametros{PORCENTAJE()};
  if($user_sistema_id eq "") {
    $user_sistema_id = '\d+';
  }
  my($ref_comparativa) = cargar_comparativa($user_pais_id, $user_sistema_id, $fecha_desde, $fecha_hasta);
  my(@resultados);
  foreach my $sistema_id (keys(%$ref_comparativa)) {
    foreach my $prestamo_id (keys(%{$ref_comparativa->{$sistema_id}})) {
      my($mt_rest_maestro) = $ref_comparativa->{$sistema_id}->{$prestamo_id}->{"mt_rest_maestro"};
      my($mt_rest_prestamos) = $ref_comparativa->{$sistema_id}->{$prestamo_id}->{"mt_rest_prestamos"};
      my($diferencia_absoluta) = abs($mt_rest_maestro - $mt_rest_prestamos);
      my($diferencia_porcentual_absoluta) = ($diferencia_absoluta / $mt_rest_maestro) * 100;
      my($listar) = "no se lista";
      if($diferencia_porcentual_absoluta > $porcentaje) {
        $listar = "se lista";
      }
      my(@salida) = ($user_pais_id, $sistema_id, $prestamo_id, $listar, $mt_rest_maestro, $mt_rest_prestamos, $diferencia_absoluta, $diferencia_porcentual_absoluta);
      push(@resultados, \@salida);
    }
  }
  procesar_resultados_divergencia(\@resultados, $opcion_grabar);
  return @resultados;
}

sub procesar_resultados_comparativa {
  my($ref_resultados, $grabar) = ($_[0], $_[1]);
  print "┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐\n";
  print "│ Cod. País │ Cod. Sist. │  Cod. Prest.  │ RECOMEND. │ Est. Cont. M. │ Est. Cont. P. │ Monto Rest. M │ Monto Rest. P. │ Diferencia (M-P) │  Año  │ Mes │ Dia M. │ Día P. │\n";
  print "├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤\n";
  foreach my $resultado (@$ref_resultados) {
    $$resultado[8] = sprintf("%.2f", $$resultado[8]);
    $$resultado[8] =~ s/\./,/;
    if($grabar eq "GRABAR") {
      my($linea) = join(";", @$resultado);
      print REPORTE_C "$linea\n";
    }
  open STDOUT1, ">-" or die "Error: $!\n";
  format STDOUT1 =
│ @|||||||| │ @||||||||| │ @>>>>>>>>>>>> │ @>>>>>>>> │ @>>>>>>>>>>>> │ @>>>>>>>>>>>> │ @>>>>>>>>>>>> │ @>>>>>>>>>>>>> │ @>>>>>>>>>>>>>>> │ @>>>> │ @>> │ @>>>>> │ @>>>>> │
  @$resultado
.
  write STDOUT1;
  }
  my($lineas) = @$ref_resultados;
  if($lineas == 0) {
    print "│------------------------------------------------------------------------------no hay datos------------------------------------------------------------------------------│\n";
  }
  print "└────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘\n";
  close(REPORTE_C);
}

sub buscar_mayor_fecha {
  my(@fechas) = @_;
  my(@fechas_modificadas);
  foreach my $fecha (@fechas) {
    $fecha =~ s#(\d\d)/(\d\d)/(\d\d\d\d)#\3\2\1#;
    push(@fechas_modificadas, $fecha);
  }
  my(@fechas_ordenadas) = sort { $a <=> $b } @fechas_modificadas;
  my($fecha_mayor) = $fechas_ordenadas[-1];
  $fecha_mayor =~ s#(\d\d\d\d)(\d\d)(\d\d)#\3/\2/\1#;
  return $fecha_mayor;
}

sub cargar_prestamos_por_pais {
  my($user_pais_id, $user_sistema_id) = ($_[0], $_[1]);
  my($un_prestamo, $sistema_id, $prestamo_id, @campos, @claves, %prestamo, %todos_los_prestamos);
  while($un_prestamo = <PRESTAMOS>) {
    if($un_prestamo =~ /^$user_sistema_id;.*/) {
      $un_prestamo =~ s/\r?\n$//;
      @campos = split(";", $un_prestamo);
      if(@campos != NRO_CAMPOS_PRESTAMOS()) {
        print "Registro mal formado en el archivo de prestamos:\n";
        print "$un_prestamo\n";
      } else {
        @claves = ("ctb_anio", "ctb_mes", "ctb_dia", "ctb_estado", "pres_id", "mt_pres", "mt_impago", "mt_inde", "mt_innode", "mt_deb", "mt_rest", "pres_cli_id", "pres_cli", "ins_fe", "ins user");
        $sistema_id = shift(@campos);
        my(%prestamo);
        @prestamo{@claves} = @campos;
        $prestamo_id = $prestamo{"pres_id"};
        my($prestamo_anio, $prestamo_mes, $prestamo_dia) = ($prestamo{"ctb_anio"}, $prestamo{"ctb_mes"}, $prestamo{"ctb_dia"});
        my($prestamo_actualizacion) = $prestamo{"ins_fe"};
        delete @prestamo{"pres_id", "ctb_anio", "ctb_mes", "ctb_dia", "mt_pres", "mt_impago", "mt_inde", "mt_innode", "mt_deb", "pres_cli_id", "pres_cli", "ins_fe", "ins user"};
        $prestamo{"mt_rest"} =~ s/,/\./;
        $todos_los_prestamos{$sistema_id}{$prestamo_id}{$prestamo_anio}{$prestamo_mes}{$prestamo_dia}{$prestamo_actualizacion} = \%prestamo;
        #$todos_los_prestamos{$sistema_id}{$prestamo_id} = {%prestamo};
      }
    }
  }
  close(PRESTAMOS);
  return \%todos_los_prestamos;
}

sub cargar_maestro {
  my($user_pais_id, $user_sistema_id) = ($_[0], $_[1]);
  my($fecha_desde, $fecha_hasta) = ($_[2], $_[3]);
  my($un_prestamo, $sistema_id, $prestamo_id, @campos, @claves, %prestamo, %todos_los_prestamos);
  while($un_prestamo = <MAESTRO>) {
    if($un_prestamo =~ /^$user_pais_id;$user_sistema_id;.*/) {
      $un_prestamo =~ s/\r?\n$//;
      @campos = split(";", $un_prestamo);
      if(@campos != NRO_CAMPOS_MAESTRO()) {
        print "Registro mal formado en el archivo maestro:\n";
        print "$un_prestamo\n";
      } else {
        @claves = ("ctb_anio", "ctb_mes", "ctb_dia", "ctb_estado", "pres_fe", "pres_id", "pres_ti", "mt_pres", "mt_impago", "mt_inde", "mt_innode", "mt_deb");
        shift(@campos);
        $sistema_id = shift(@campos);
        my(%prestamo);
        @prestamo{@claves} = @campos;
        my($fecha_prestamo) = Time::Piece->strptime($prestamo{"ctb_anio"}." ".$prestamo{"ctb_mes"}." ".$prestamo{"ctb_dia"}, "%Y %m %d");
        if(fecha_en_intervalo($fecha_desde, $fecha_hasta, \$fecha_prestamo)) {
          $prestamo_id = $prestamo{"pres_id"};
          my($mt_pres, $mt_impago, $mt_inde, $mt_innode, $mt_deb) = ($prestamo{"mt_pres"}, $prestamo{"mt_impago"}, $prestamo{"mt_inde"}, $prestamo{"mt_innode"}, $prestamo{"mt_deb"});
          $mt_pres =~ s/,/\./; $mt_impago =~ s/,/\./; $mt_inde =~ s/,/\./; $mt_innode =~ s/,/\./; $mt_deb =~ s/,/\./;
          my($mt_rest) = $mt_pres + $mt_impago + $mt_inde + $mt_innode - $mt_deb;
          #$mt_rest =~ s/\./,/;
          $prestamo{"mt_rest"} = $mt_rest;
          #print $mt_rest." = ".$prestamo{mt_pres}." + ".$prestamo{mt_impago}." + ".$prestamo{mt_inde}." + ".$prestamo{mt_innode}." - ".$prestamo{mt_deb}."\n";
          delete @prestamo{"pres_fe", "pres_id", "pres_ti", "mt_pres", "mt_impago", "mt_inde", "mt_innode", "mt_deb"};
          $todos_los_prestamos{$sistema_id}{$prestamo_id} = \%prestamo;
          #$todos_los_prestamos{$sistema_id}{$prestamo_id} = {%prestamo};
        }
      }
    }
  }
  close(MAESTRO);
  return \%todos_los_prestamos;
}

sub procesar_comparativa {
  my($comando, $ref_parametros, $opcion_grabar) = ($_[0], $_[1], $_[2]);
  my($user_pais_id, $user_sistema_id) = ($$ref_parametros{CODIGO_PAIS()}, $$ref_parametros{CODIGO_SISTEMA()});
  my($fecha_desde, $fecha_hasta) = ($$ref_parametros{FECHA_DESDE()}, $$ref_parametros{FECHA_HASTA()});
  if($user_sistema_id eq "") {
    $user_sistema_id = '\d+';
  }
  my($ref_maestro) = cargar_maestro($user_pais_id, $user_sistema_id, $fecha_desde, $fecha_hasta);
  my($ref_prestamos) = cargar_prestamos_por_pais($user_pais_id, $user_sistema_id, $fecha_desde, $fecha_hasta);
  my(@resultados);
  foreach my $sistema_id (keys(%$ref_maestro)) {
    foreach my $prestamo_id (keys(%{$ref_maestro->{$sistema_id}})) {
      my($prestamo_anio) = $ref_maestro->{$sistema_id}->{$prestamo_id}->{"ctb_anio"};
      my($prestamo_mes) = $ref_maestro->{$sistema_id}->{$prestamo_id}->{"ctb_mes"};
      if(exists($ref_prestamos->{$sistema_id}->{$prestamo_id}->{$prestamo_anio}->{$prestamo_mes})) {
        my(@dias) = keys(%{$ref_prestamos->{$sistema_id}->{$prestamo_id}->{$prestamo_anio}->{$prestamo_mes}});
        my(@dias_ordenados) = sort { $a <=> $b } @dias;
        my(@fechas) = keys(%{$ref_prestamos->{$sistema_id}->{$prestamo_id}->{$prestamo_anio}->{$prestamo_mes}->{$dias_ordenados[-1]}});
        my($mayor_fecha) = $fechas[0];
        if(@fechas > 1) {
          $mayor_fecha = buscar_mayor_fecha(@fechas);
        }
        my($mt_rest_maestro) = $ref_maestro->{$sistema_id}->{$prestamo_id}->{"mt_rest"};
        my($mt_rest_prestamos) = $ref_prestamos->{$sistema_id}->{$prestamo_id}->{$prestamo_anio}->{$prestamo_mes}->{$dias_ordenados[-1]}->{$mayor_fecha}->{"mt_rest"};
        my($diferencia) = $mt_rest_maestro - $mt_rest_prestamos;
        my($ctb_estado_maestro) = $ref_maestro->{$sistema_id}->{$prestamo_id}->{"ctb_estado"};
        my($ctb_estado_prestamos) = $ref_prestamos->{$sistema_id}->{$prestamo_id}->{$prestamo_anio}->{$prestamo_mes}->{$dias_ordenados[-1]}->{$mayor_fecha}->{"ctb_estado"};
        my($conflicto_estados) = "NO-RECAL";
        if($diferencia < 0) {
          $conflicto_estados = "RECAL";
        }
        if(($ctb_estado_maestro eq "SMOR") && ($ctb_estado_prestamos ne "SMOR")) {
          $conflicto_estados = "RECAL";
        }
        my($prestamo_dia) = $ref_maestro->{$sistema_id}->{$prestamo_id}->{"ctb_dia"};
        my(@salida) = ($user_pais_id, $sistema_id, $prestamo_id, $conflicto_estados, $ctb_estado_maestro, $ctb_estado_prestamos, $mt_rest_maestro, $mt_rest_prestamos, $diferencia, $prestamo_anio, $prestamo_mes, $prestamo_dia, $dias_ordenados[-1]);
        push(@resultados, \@salida);
      }
    }
  }
  procesar_resultados_comparativa(\@resultados, $opcion_grabar);
  return @resultados;
}

sub no_grabar {
  my($comando) = $_[0];
  if($comando eq "c") {
    my($ref_parametros) = recibir_parametros_comparativa();
    if(preparar_archivos_entrada_comparativa($ref_parametros)) {
      procesar_comparativa($comando, $ref_parametros, "NO GRABAR");
    }
  } elsif($comando eq "dp") {
      my($ref_parametros) = recibir_parametros_divergencia_porcentual();
      if(preparar_archivo_entrada_divergencia($ref_parametros)) {
        procesar_divergencia_porcentual($comando, $ref_parametros, "NO GRABAR");
      }
  } elsif($comando eq "da") {
    my($ref_parametros) = recibir_parametros_divergencia_absoluta();
    if(preparar_archivo_entrada_divergencia($ref_parametros)) {
      procesar_divergencia_absoluta($comando, $ref_parametros, "NO GRABAR");
    }
  }
}

sub conseguir_ultimo_numero {
  my($ruta_absoluta_reportes) = $_[0];
  my($nombre_archivo_divergencia) = $_[1];
  my($ruta_absoluta_archivo_divergencia) = $_[2];
  if(! opendir(DIRECTORIO, "$ruta_absoluta_reportes")) {
    print "No se pudo abrir el directorio \"$ruta_absoluta_reportes\".\n";
    return "";
  } else {
    @lista_archivos = readdir(DIRECTORIO);
    my(@numeros);
    foreach my $nombre_archivo (@lista_archivos) {
      if($nombre_archivo =~ s/^\Q$nombre_archivo_divergencia\E\.([\d]+)$/\1/) {
        $nombre_archivo += 0;
        push(@numeros, $nombre_archivo);
      }
    }
    my(@numeros_ordenados) = sort { $a <=> $b } @numeros;
    closedir(DIRECTORIO);
    if(@numeros_ordenados == 0) {
      return 0;
    } else {
      return $numeros_ordenados[-1];
    }
  }
}

sub preparar_archivo_salida_divergencia {
  my($ref_parametros) = $_[0];
  my($codigo_pais) = $$ref_parametros{CODIGO_PAIS()};
  my($nombre_archivo_divergencia) = NOMBRE_ARCHIVO_COMPARADO().".$codigo_pais";
  my($ruta_absoluta_archivo_divergencia) = "$ruta_absoluta_reportes/$nombre_archivo_divergencia";
  if(! -d -r -w -x "$ruta_absoluta_reportes") {
    print "No tiene flags \"-d\", \"-r\", \"-w\", y \"-x\" el directorio \"$ruta_absoluta_reportes\".\n";
    return 0;
  } else {
    my($numero_de_archivo) = conseguir_ultimo_numero($ruta_absoluta_reportes, $nombre_archivo_divergencia, $ruta_absoluta_archivo_divergencia);
    if ($numero_de_archivo eq "") {
      return 0;
    } else {
      ++$numero_de_archivo;
      if(! open(REPORTE_D, ">$ruta_absoluta_archivo_divergencia.$numero_de_archivo")) {
        print "No se pudo abrir para escribir el archivo \"$ruta_absoluta_archivo_divergencia.$numero_de_archivo\".\n";
        return 0;
      } else {
        return 1;
      }
    }
  }
}

sub preparar_archivo_salida_comparativa {
  my($ref_parametros) = $_[0];
  my($codigo_pais) = $$ref_parametros{CODIGO_PAIS()};
  my($ruta_absoluta_archivo_comparativa) = "$ruta_absoluta_reportes/".NOMBRE_ARCHIVO_COMPARADO().".$codigo_pais";
  if(! -d -w -x "$ruta_absoluta_reportes") {
    print "No tiene flags \"-d\", \"-w\", y \"-x\" el directorio \"$ruta_absoluta_reportes\".\n";
    return 0;
  } else {
    if(! open(REPORTE_C, ">>$ruta_absoluta_archivo_comparativa")) {
      print "No se pudo abrir para appendear el archivo \"$ruta_absoluta_archivo_comparativa\".\n";
      return 0;
    } else {
      return 1;
    }
  }
}

sub preparar_archivo_entrada_divergencia {
  my($ref_parametros) = $_[0];
  my($codigo_pais) = $$ref_parametros{CODIGO_PAIS()};
  my($ruta_absoluta_archivo_comparativa) = "$ruta_absoluta_reportes/".NOMBRE_ARCHIVO_COMPARADO().".$codigo_pais";
  if(! -d -x "$ruta_absoluta_reportes") {
    print "No tiene flags \"-d\" y \"-x\" el directorio \"$ruta_absoluta_reportes\".\n";
    return 0;
  } else {
    if(! -f -r "$ruta_absoluta_archivo_comparativa") {
      print "No tiene flags \"-f\" y \"-r\" el archivo \"$ruta_absoluta_archivo_comparativa\".\n";
      return 0;
    } else {
      if(-z "$ruta_absoluta_archivo_comparativa") {
        print "Está vacío el archivo \"$ruta_absoluta_archivo_comparativa\".\n";
        return 0;
      } else {
        if(! open(COMPARATIVA, "<$ruta_absoluta_archivo_comparativa")) {
          print "No se pudo abrir para lectura el archivo \"$ruta_absoluta_archivo_comparativa\".\n";
          return 0;
        } else {
          return 1;
        }
      }
    }
  }
}

sub preparar_archivos_entrada_comparativa {
  my($ref_parametros) = $_[0];
  my($codigo_pais, $codigo_sistema) = ($$ref_parametros{CODIGO_PAIS()}, $$ref_parametros{CODIGO_SISTEMA()});
  my($ruta_absoluta_archivo_maestros) = "$ruta_absoluta_maestros/".NOMBRE_ARCHIVO_MAESTRO_PRESTAMOS();
  my($ruta_absoluta_archivo_prestamos) = "$ruta_absoluta_procesados/".NOMBRE_ARCHIVO_PRESTAMOS().".$codigo_pais";
  #TODO(Iván): Busca el archivo con la letra del <codigo de país> en mayúscula, solamente.
  if(! -d -x "$ruta_absoluta_maestros") {
    print "No tiene flags \"-d\" y \"-x\" el directorio \"$ruta_absoluta_maestros\".\n";
    return 0;
  } else {
    if(! -f -r "$ruta_absoluta_archivo_maestros") {
      print "No tiene flags \"-f\" y \"-r\" el archivo \"$ruta_absoluta_archivo_maestros\".\n";
      return 0;
    } else {
      if(-z "$ruta_absoluta_archivo_maestros") {
        print "Está vacío el archivo \"$ruta_absoluta_archivo_maestros\".\n";
        return 0;
      } else {
        if(! -d -x "$ruta_absoluta_procesados") {
          print "No tiene flags \"-d\" y \"-x\" el directorio \"$ruta_absoluta_procesados\".\n";
          return 0;
        } else {
          if(! -f -r "$ruta_absoluta_archivo_prestamos") {
            print "No tiene flags \"-f\" y \"-r\" el archivo \"$ruta_absoluta_archivo_prestamos\".\n";
            return 0;
          } else {
            if(-z "$ruta_absoluta_archivo_prestamos") {
              print "Está vacío el archivo \"$ruta_absoluta_archivo_prestamos\".\n";
              return 0;
            } else {
              if(! open(MAESTRO, "<$ruta_absoluta_archivo_maestros")) {
                print "No se pudo abrir para lectura el archivo \"$ruta_absoluta_archivo_maestros\".\n";
                return 0;
              } else {
                if(! open(PRESTAMOS, "<$ruta_absoluta_archivo_prestamos")) {
                  close(MAESTRO);
                  print "No se pudo abrir para lectura el archivo \"$ruta_absoluta_archivo_prestamos\".\n";
                  return 0;
                } else {
                  return 1;
}}}}}}}}}

sub recibir_valor_absoluto {
  print "Elija el valor absoluto de referencia para discriminar divergencias: ingrese el <valor absoluto> \n";
  print "correspondiente y luego presione la tecla \"enter\". El <valor absoluto> consiste de un número \n";
  print "entero positivo. Las divergencias se discriminan en variación absoluta (sin signo).\n";
  my($valor_absoluto);
  while(! $valor_absoluto) {
    print "Su <valor absoluto> [OBLIGATORIO]: ";
    $valor_absoluto = <STDIN>;
    chomp($valor_absoluto);
    if(! ($valor_absoluto =~ /^\d+$/)) {
      $valor_absoluto = "";
      print "ERROR: El <valor absoluto> consiste de un número entero positivo (sin signo).\n";
    }
  }
  return $valor_absoluto;
}

sub recibir_porcentaje {
  print "Elija el porcentaje de referencia para discriminar divergencias: ingrese el <porcentaje> \n";
  print "correspondiente y luego presione la tecla \"enter\". El <porcentaje> consiste de un número \n";
  print "entero positivo. Las divergencias se discriminan en variación absoluta (sin signo).\n";
  my($porcentaje);
  while(! $porcentaje) {
    print "Su <porcentaje> [OBLIGATORIO]: ";
    $porcentaje = <STDIN>;
    chomp($porcentaje);
    if(! ($porcentaje =~ /^\d+$/)) {
      $porcentaje = "";
      print "ERROR: El <porcentaje> consiste de un número entero positivo (sin signo).\n";
    }
  }
  return $porcentaje;
}

sub procesar_fecha_hasta {
  #Si no ingresa mes/día, se supone que se incluye todo el año/mes ingresado, respectivamente.
  my($anio, $mes, $dia) = ($_[0], $_[1], $_[2]);
  my($fecha_hasta);
  if($mes eq "") {
    $anio += 1;
    $mes = 1;
    $dia = 1;
    $fecha_hasta = Time::Piece->strptime($anio." ".$mes." ".$dia, "%Y %m %d");
    $fecha_hasta -= ONE_DAY;
  } else {
    if($dia eq "") {
      $dia = 1;
      $fecha_hasta = Time::Piece->strptime($anio." ".$mes." ".$dia, "%Y %m %d");
      $dias_en_mes = $fecha_hasta->month_last_day;
      $fecha_hasta = Time::Piece->strptime($anio." ".$mes." ".$dias_en_mes, "%Y %m %d");
    } else {
      $fecha_hasta = Time::Piece->strptime($anio." ".$mes." ".$dia, "%Y %m %d");
    }
  }
  return \$fecha_hasta; #Es la referencia al objeto Time::Piece.
}

sub procesar_fecha_desde {
  #Si no ingresa mes/día, se supone que se incluye todo el año/mes ingresado, respectivamente.
  my($anio, $mes, $dia) = ($_[0], $_[1], $_[2]);
  if($mes eq "") {
    $mes = 1;
    $dia = 1;
  } elsif($dia eq "") {
    $dia = 1;
  }
  my($fecha_desde) = Time::Piece->strptime($anio." ".$mes." ".$dia, "%Y %m %d");
  return \$fecha_desde; #Es la referencia al objeto Time::Piece.
}

sub recibir_dia {
  my($anio, $mes) = ($_[0], $_[1]);
  my($dia);
  if($mes ne "") {
    $dia = AUN_NO();
    while($dia eq AUN_NO()) {
      print "                            -su <día> [OPCIONAL] (ingrese el número de día, ej.: 4): ";
      $dia = <STDIN>;
      chomp($dia);
      if($dia ne "") {
        if(! ($dia =~ /^(0?[1-9]|[1-2]?\d|(3[0-1]))$/)) {
          print "                            ERROR: El <día> consiste de un número entero, ej.: 13.\n";
          $dia = AUN_NO();
        } else {
          if(system("date -d $anio/$mes/$dia +%Y/%m/%d > /dev/null 2>&1")) {
            print "                            ERROR: La fecha $anio/$mes/$dia no existe.\n";
            $dia = AUN_NO();
          }
        }
      }
    }
  } else {
    $dia = "";
  }
  return $dia;
}

sub recibir_mes {
  my($mes) = AUN_NO();
  while($mes eq AUN_NO()) {
    print "                            -su <mes> [OPCIONAL] (ej.: para \"Febrero\" ingrese 2): ";
    $mes = <STDIN>;
    chomp($mes);
    if(($mes ne "") && (! ($mes =~ /^(0?[1-9]|(1[0-2]))$/))) {
      print "                            ERROR: El <mes> consiste de un número entero, ej.: para \"Noviembre\" ingrese 11.\n";
      $mes = AUN_NO();
    }
  }
  return $mes;
}

sub recibir_anio {
  my($anio) = AUN_NO();
  while($anio eq AUN_NO()) {
    print "                            -su <año> [OPCIONAL] (ingrese todos los dígitos, ej.: 2018): ";
    $anio = <STDIN>;
    chomp($anio);
    if(($anio ne "") && (! ($anio =~ /^[0-9]*$/))) {
      print "                            ERROR: El <año> consiste de un número entero, ej.: 1998.\n";
      $anio = AUN_NO();
    }
  }
  return $anio;
}

sub recibir_fecha {
  my($anio) = recibir_anio();
  my($mes, $dia);
  if($anio ne "") {
    $mes = recibir_mes();
    $dia = recibir_dia($anio, $mes);
  }
  return ($anio, $mes, $dia);
}

sub recibir_fecha_hasta {
  print "Elija la fecha contable hasta la cual desea realizar la comparativa (se incluye esta fecha \n";
  print "extremo). Si no ingresa mes/día, se supone que se incluye todo el año/mes ingresado, respectivamente.\n";
  print "Si no desea filtrar por <fecha hasta>, simplemente presione la tecla \"enter\".\n";
  print "Su <fecha hasta> [OPCIONAL]:\n";
  my(@fecha_hasta) = recibir_fecha();
  if($fecha_hasta[0] eq "") {
    return "";
  } else {
    $fecha_hasta = procesar_fecha_hasta(@fecha_hasta); #Si no ingresa mes/día, se supone que se incluye todo el año/mes ingresado, respectivamente.
    return $fecha_hasta; #Es la referencia al objeto Time::Piece.
  }
}

sub recibir_fecha_desde {
  print "Elija la fecha contable a partir de la cual desea realizar la comparativa (se incluye esta \n";
  print "fecha extremo). Si no ingresa mes/día, se supone que se incluye todo el año/mes ingresado, \n";
  print "respectivamente.\n";
  print "Si no desea filtrar por <fecha desde>, simplemente presione la tecla \"enter\".\n";
  print "Su <fecha desde> [OPCIONAL]:\n";
  my(@fecha_desde) = recibir_fecha();
  if(@fecha_desde[0] eq "") {
    return "";
  } else {
    $fecha_desde = procesar_fecha_desde(@fecha_desde); #Si no ingresa mes/día, se supone que se incluye todo el año/mes ingresado, respectivamente.
    return $fecha_desde; #Es la referencia al objeto Time::Piece.
  }
}

sub recibir_codigo_sistema {
  print "Elija el sistema para el cual desea realizar la comparativa: ingrese el <código de sistema> \n";
  print "correspondiente y luego presione la tecla \"enter\". El <código de país> consiste de un número.\n";
  print "entero. Si no desea filtrar por código de sistema, simplemente presione la tecla \"enter\".\n";
  my($codigo_sistema) = AUN_NO();
  while($codigo_sistema eq AUN_NO()) {
    print "Su <código de sistema> [OPCIONAL]: ";
    $codigo_sistema = <STDIN>;
    chomp($codigo_sistema);
    if(($codigo_sistema ne "") && (! ($codigo_sistema =~ /^[0-9]*$/))) {
      print "ERROR: El <código de sistema> consiste de un número entero.\n";
      $codigo_sistema = AUN_NO();
    }
  }
  return $codigo_sistema;
}

sub recibir_codigo_pais {
  print "Elija el país para el cual desea realizar la comparativa: ingrese el <código de país> \n";
  print "correspondiente y luego presione la tecla \"enter\". El <código de país> consiste de un único \n";
  print "caracter.\n";
  my($codigo_pais);
  while(! $codigo_pais) {
    print "Su <código de país> [OBLIGATORIO]: ";
    $codigo_pais = <STDIN>;
    chomp($codigo_pais);
    $codigo_pais = uc($codigo_pais);
    if(! ($codigo_pais =~ /^[A-Z]$/)) {
      $codigo_pais = "";
      print "ERROR: El <código de país> consiste de un único caracter.\n";
    }
  }
  return $codigo_pais;
}

sub recibir_parametros_divergencia_absoluta {
  print "\n";
  my(%parametros);
  $parametros{CODIGO_PAIS()} = recibir_codigo_pais();
  print "\n";
  $parametros{CODIGO_SISTEMA()} = recibir_codigo_sistema();
  print "\n";
  $parametros{FECHA_DESDE()} = recibir_fecha_desde(); #Es la referencia al objeto Time::Piece o una cadena vacía (si no se desea filtrar por <fecha desde>).
  print "\n";
  $parametros{FECHA_HASTA()} = recibir_fecha_hasta(); #Es la referencia al objeto Time::Piece o una cadena vacía (si no se desea filtrar por <fecha hasta>).
  $parametros{VALOR_ABSOLUTO()} = recibir_valor_absoluto();
  my($fecha_desde, $fecha_hasta);
  if($parametros{FECHA_DESDE()} eq '') {
    $fecha_desde = "";
  } else {
    $fecha_desde = $parametros{FECHA_DESDE()};
    $fecha_desde = $$fecha_desde;
    $fecha_desde = $fecha_desde->strftime("%d/%m/%Y");
  }
  if($parametros{FECHA_HASTA()} eq '') {
    $fecha_hasta = "";
  } else {
    $fecha_hasta = $parametros{FECHA_HASTA()};
    $fecha_hasta = $$fecha_hasta;
    $fecha_hasta = $fecha_hasta->strftime("%d/%m/%Y");
  }
  print "Consulta de divergencia pocentual por <código de país> = \"".$parametros{CODIGO_PAIS()}."\", <código de sistema> = \"".$parametros{CODIGO_SISTEMA()}."\", <fecha desde> = \"".$fecha_desde."\", <fecha hasta> = \"".$fecha_hasta."\", <valor absoluto> = \"".$parametros{VALOR_ABSOLUTO()}."\"\n";
  return \%parametros; #Es la referencia al hash.
}

sub recibir_parametros_divergencia_porcentual {
  print "\n";
  my(%parametros);
  $parametros{CODIGO_PAIS()} = recibir_codigo_pais();
  print "\n";
  $parametros{CODIGO_SISTEMA()} = recibir_codigo_sistema();
  print "\n";
  $parametros{FECHA_DESDE()} = recibir_fecha_desde(); #Es la referencia al objeto Time::Piece o una cadena vacía (si no se desea filtrar por <fecha desde>).
  print "\n";
  $parametros{FECHA_HASTA()} = recibir_fecha_hasta(); #Es la referencia al objeto Time::Piece o una cadena vacía (si no se desea filtrar por <fecha hasta>).
  $parametros{PORCENTAJE()} = recibir_porcentaje();
  my($fecha_desde, $fecha_hasta);
  if($parametros{FECHA_DESDE()} eq '') {
    $fecha_desde = "";
  } else {
    $fecha_desde = $parametros{FECHA_DESDE()};
    $fecha_desde = $$fecha_desde;
    $fecha_desde = $fecha_desde->strftime("%d/%m/%Y");
  }
  if($parametros{FECHA_HASTA()} eq '') {
    $fecha_hasta = "";
  } else {
    $fecha_hasta = $parametros{FECHA_HASTA()};
    $fecha_hasta = $$fecha_hasta;
    $fecha_hasta = $fecha_hasta->strftime("%d/%m/%Y");
  }
  print "Consulta de divergencia pocentual por <código de país> = \"".$parametros{CODIGO_PAIS()}."\", <código de sistema> = \"".$parametros{CODIGO_SISTEMA()}."\", <fecha desde> = \"".$fecha_desde."\", <fecha hasta> = \"".$fecha_hasta."\", <porcentaje> = \"".$parametros{PORCENTAJE()}."\"\n";
  return \%parametros; #Es la referencia al hash.
}

sub recibir_parametros_comparativa {
  print "\n";
  my(%parametros);
  $parametros{CODIGO_PAIS()} = recibir_codigo_pais();
  print "\n";
  $parametros{CODIGO_SISTEMA()} = recibir_codigo_sistema();
  print "\n";
  $parametros{FECHA_DESDE()} = recibir_fecha_desde(); #Es la referencia al objeto Time::Piece o una cadena vacía (si no se desea filtrar por <fecha desde>).
  print "\n";
  $parametros{FECHA_HASTA()} = recibir_fecha_hasta(); #Es la referencia al objeto Time::Piece o una cadena vacía (si no se desea filtrar por <fecha hasta>).
  my($fecha_desde, $fecha_hasta);
  if($parametros{FECHA_DESDE()} eq '') {
    $fecha_desde = "";
  } else {
    $fecha_desde = $parametros{FECHA_DESDE()};
    $fecha_desde = $$fecha_desde;
    $fecha_desde = $fecha_desde->strftime("%d/%m/%Y");
  }
  if($parametros{FECHA_HASTA()} eq '') {
    $fecha_hasta = "";
  } else {
    $fecha_hasta = $parametros{FECHA_HASTA()};
    $fecha_hasta = $$fecha_hasta;
    $fecha_hasta = $fecha_hasta->strftime("%d/%m/%Y");
  }
  print "Consulta comparativa por <código de país> = \"".$parametros{CODIGO_PAIS()}."\", <código de sistema> = \"".$parametros{CODIGO_SISTEMA()}."\", <fecha desde> = \"".$fecha_desde."\", <fecha hasta> = \"".$fecha_hasta."\"\n";
  return \%parametros; #Es la referencia al hash.
}

sub grabar {
  my($comando) = $_[0];
  if($comando eq "c") {
    my($ref_parametros) = recibir_parametros_comparativa();
    if(preparar_archivos_entrada_comparativa($ref_parametros)) {
      if(preparar_archivo_salida_comparativa($ref_parametros)) {
        procesar_comparativa($comando, $ref_parametros, "GRABAR");
      }
    }
  } elsif($comando eq "dp") {
      my($ref_parametros) = recibir_parametros_divergencia_porcentual();
      if(preparar_archivo_entrada_divergencia($ref_parametros)) {
        if(preparar_archivo_salida_divergencia($ref_parametros)) {
          procesar_divergencia_porcentual($comando, $ref_parametros, "GRABAR");
        }
      }
  } elsif($comando eq "da") {
    my($ref_parametros) = recibir_parametros_divergencia_absoluta();
    if(preparar_archivo_entrada_divergencia($ref_parametros)) {
      if(preparar_archivo_salida_divergencia($ref_parametros)) {
        procesar_divergencia_absoluta($comando, $ref_parametros, "GRABAR");
      }
    }
  }
}

sub esperar_confirmacion_ayuda {
  #print "Presione la tecla \"enter\" para volver al menú de consultas.";
}

sub ayuda_divergencia_absoluta {
  #TODO(Iván): Agregar rutas de archivos necesarios y sus nombres.
  print "\n";
  print "Ayuda de consulta por \"divergencia absoluta\":\n";
  print "---------------------------------------------\n";
  print "A partir del archivo generado en una consulta \"por comparativa\" anterior, para el país \n";
  print "seleccionado, se calcula la diferencia entre los dos montos restantes calculados para cada \n";
  print "préstamo. Si la diferencia es mayor al valor indicado por el usuario, el préstamo es listado \n";
  print "por pantalla.\n";
  print "\n";
  print "Este comando requiere que se ingrese un código de país, y da la posibilidad de ingresar un \n";
  print "código de sistema y/o un intervalo de fechas (ambos extremos del intervalo incluídos) que \n";
  print "se utilizaran para filtrar los prestamos a ser \"listados\". También se solicita al usuario \n";
  print "el valor absoluto a utilizarse como criterio de corte. Este valor se debe ingresar como un \n";
  print "valor positivo, pero se utiliza para determinar la diferencia máxima en más y en menos.\n";
  print "\n";
  print "Este comando muestra los resultados por pantalla en forma de un listado, pero también permite \n";
  print "que se genere un archivo de salida con el listado mencionado, el cual será grabado en el \n";
  print "directorio \"$ruta_absoluta_reportes\", \n";
  print "bajo un nombre consistente de un número de secuencia autoincremental.\n";
  esperar_confirmacion_ayuda();
}

sub ayuda_divergencia_porcentual {
  #TODO(Iván): Agregar rutas de archivos necesarios y sus nombres
  print "\n";
  print "Ayuda de consulta por \"divergencia porcentual\":\n";
  print "-----------------------------------------------\n";
  print "A partir del archivo generado en una consulta \"por comparativa\" anterior, para el país \n";
  print "seleccionado, se calcula la diferencia entre los dos montos restantes calculados para cada \n";
  print "préstamo, expresándolo como un porcentaje del monto correspondiente al cálculo a partir del \n";
  print "archivo maestro. Si el porcentaje de diferencia es mayor al porcentaje indicado por el \n";
  print "usuario, el préstamo es listado por pantalla.\n";
  print "\n";
  print "Este comando requiere que se ingrese un código de país, y da la posibilidad de ingresar un \n";
  print "código de sistema y/o un intervalo de fechas (ambos extremos del intervalo incluídos) que \n";
  print "se utilizaran para filtrar los prestamos a ser \"listados\". También se solicita al usuario \n";
  print "el valor porcentual a utilizarse como criterio de corte. El valor porcentual se debe ingresar \n";
  print "como un valor positivo, pero se utiliza para determinar la diferencia máxima en más y en menos.\n";
  print "\n";
  print "Este comando muestra los resultados por pantalla en forma de un listado, pero también permite \n";
  print "que se genere un archivo de salida con el listado mencionado, el cual será grabado en el \n";
  print "directorio \"$ruta_absoluta_reportes\", \n";
  print "bajo un nombre consistente de un número de secuencia autoincremental.\n";
  print "\n";
  esperar_confirmacion_ayuda();
}

sub ayuda_comparativa {
  #TODO(Iván): Agregar rutas de archivos necesarios y sus nombres
  print "\n";
  print "Ayuda de consulta por \"comparativa\":\n";
  print "------------------------------------\n";
  print "Este comando calcula los valores del monto restante de los prestamos según el archivo maestro \n";
  print "y según el registro más actualizado del archivo correspondiente de \"PRESTAMOS.<pais>\" \n";
  print "(en caso de que exista alguno), y realiza la comparación entre ambos valores, determinando \n";
  print "si se recomienda o no recalcular el préstamo.\n";
  print "\n";
  print "Este comando requiere que se ingrese un código de país, y da la posibilidad de ingresar un \n";
  print "código de sistema y/o un intervalo de fechas (ambos extremos del intervalo incluídos) que \n";
  print "se utilizaran para filtrar los prestamos a ser \"comparados\".\n";
  print "\n";
  print "Este comando muestra los resultados por pantalla en forma de un listado, indicando si se \n";
  print "recomienda o no la recalculación del préstamo. El comando también permite que se genere un \n";
  print "archivo de salida con el listado mencionado, el cual será grabado en el directorio \n";
  print "\"$ruta_absoluta_reportes\", \n";
  print "bajo el nombre \"comparado.<pais>\".\n";
  print "\n";
  esperar_confirmacion_ayuda();
}

sub ayuda {
  my($comando) = $_[0];
  if($comando eq "c") {
    ayuda_comparativa();
  } elsif($comando eq "dp") {
    ayuda_divergencia_porcentual();
  } elsif($comando eq "da") {
    ayuda_divergencia_absoluta();
  }
}

sub procesar_consulta {
  my($comando, $opcion) = ($_[0], $_[1]);
  if($opcion eq "-a") {
    ayuda($comando);
  } elsif($opcion eq "-g") {
    grabar($comando);
  } elsif($opcion eq "") {
    no_grabar($comando);
  }
}

sub validar_opcion_e_informar_errores {
  my($opcion) = $_[0];
  if($opcion =~ /^(-a|-g)$/) {
    return "VALIDO";
  } else {
    print "Opción \"$opcion\" desconocida.\n";
    return 0;
  }
}

sub validar_comando_e_informar_errores {
  my($comando) = $_[0];
  if($comando =~ /^(c|dp|da)$/) {
    return "VALIDO";
  } else {
    print "Comando \"$comando\" desconocido.\n";
    return 0;
  }
}

sub validar_consulta_con_opcion_e_informar_errores {
  my($comando, $opcion) = ($_[0], $_[1]);
  if(validar_comando_e_informar_errores($comando)) {
    if(validar_opcion_e_informar_errores($opcion)) {
      return "VALIDO";
    }
  } else {
    validar_opcion_e_informar_errores($opcion);
  }
  return 0;
}

sub validar_consulta_sin_opcion_e_informar_errores {
  my($comando) = $_[0];
  if(validar_comando_e_informar_errores($comando)) {
    return "VALIDO";
  } else {
    return 0;
  }
}

sub validar_consulta_e_informar_errores {
  my(@consulta) = @_;
  if(@consulta == 0) { #TODO(Iván): Sacar esta verificación, nunca llega a ejecutarse este caso, y técnicamente no seria una consulta válida.
    return "VALIDO";
  } else {
    if(@consulta == 1) {
      return validar_consulta_sin_opcion_e_informar_errores(@consulta);
    } else {
      if(@consulta == 2) {
        return validar_consulta_con_opcion_e_informar_errores(@consulta);
      } else {
        print "Demasiados comandos u opciones (el máximo es un comando con una opción, ej.: c -a).\n";
        return 0;
      }
    }
  }
}

sub recibir_consulta {
  print "Su consulta: ";
  my($consulta);
  $consulta = <STDIN>;
  chomp($consulta);
  my(@consulta) = split(" ", $consulta);
  return @consulta;
}

sub mostrar_menu_de_consultas {
  print "Comandos:                                             Opciones:\n";
  print "   c -> Comparativa.                                    -a -> Ayuda del comando.\n";
  print "  dp -> Divergencia porcentual.                         -g -> Grabar archivo de salida.\n";
  print "  da -> Divergencia absoluta (en \$).\n";
  print "\n";
  print "Una consulta consiste de un comando y a lo sumo una opción, separados por uno o mas espacios.\n";
  print "Ingrese su consulta y presione la tecla \"enter\".\n";
  print "Por ej.:   c -g\n";
  print "           dp -a\n";
  print "Para salir, presione la tecla \"enter\".\n";
}

sub imprimir_linea_horizontal {
  system('printf \'%*s\n\' "${COLUMNS:-$(tput cols)}" \'\' | tr \' \' -');
}

sub mostrar_menu_bienvenida {
  #system("clear");
  print "Bienvenido a:\n  Producto: Consultas y Reportes: \"ReportO\".\n";
  imprimir_linea_horizontal();
}

sub preparar_ambiente_local {
  #Declara las variables necesarias.
  $ruta_absoluta_maestros =   "$ruta_absoluta_grupo02/".$ENV{NOMBRE_VARIABLE_RUTA_RELATIVA_MAESTROS()};
  $ruta_absoluta_procesados = "$ruta_absoluta_grupo02/".$ENV{NOMBRE_VARIABLE_RUTA_RELATIVA_PROCESADOS()};
  $ruta_absoluta_reportes =   "$ruta_absoluta_grupo02/".$ENV{NOMBRE_VARIABLE_RUTA_RELATIVA_REPORTES()};
}

sub script_verificador_de_ambiente() {
  #Retorna "0" si el script verifica el ambiente con éxito (dice que está correctamente inicializado), "1" en caso contrario.
  system("$ruta_absoluta_librerias/".NOMBRE_ARCHIVO_SCRIPT_INICIALIZADO());
  $exit_value = $? >> 8;
  if($exit_value != 0) {
    print "El ambiente no fue inicializado.\n";
    return 0;
  };
  return "TRUE";
}

sub verificar_script_verificador_de_ambiente() {
  #Retorna "0" si el script está en condiciones de ser invocado, "1" en caso contrario.
  #TODO(Iván): Chequear permiso "x" del directorio "$ruta_absoluta_librerias".
  if(! -f -r -x "$ruta_absoluta_librerias/".NOMBRE_ARCHIVO_SCRIPT_INICIALIZADO()){
    print "No tiene flags \"-f\", \"-r\", y \"-x\" el archivo \"$ruta_absoluta_librerias/".NOMBRE_ARCHIVO_SCRIPT_INICIALIZADO()."\".\n";
    return 0;
  } else {
    return "TRUE";
  }
}

sub verificar_variables_necesarias_para_poder_verificar_ambiente() {
  #Retorna "0" si ambas variables están inicializadas, "1" en caso contrario.
  if(! defined $ENV{NOMBRE_VARIABLE_RUTA_ABSOLUTA_GRUPO02()} || (length $ENV{NOMBRE_VARIABLE_RUTA_ABSOLUTA_GRUPO02()} == 0)) {
    print "No está seteada la variable \"\$".NOMBRE_VARIABLE_RUTA_ABSOLUTA_GRUPO02()."\".\n";
    return 0;
  } else {
    $ruta_absoluta_grupo02=$ENV{NOMBRE_VARIABLE_RUTA_ABSOLUTA_GRUPO02()};
    if(! defined $ENV{NOMBRE_VARIABLE_RUTA_RELATIVA_LIBRERIAS()} || (length $ENV{NOMBRE_VARIABLE_RUTA_RELATIVA_LIBRERIAS()} == 0)) {
      print "No está seteada la variable \"\$".NOMBRE_VARIABLE_RUTA_RELATIVA_LIBRERIAS()."\".\n";
      return 0;
    } else {
      $ruta_absoluta_librerias="$ruta_absoluta_grupo02/".$ENV{NOMBRE_VARIABLE_RUTA_RELATIVA_LIBRERIAS()};
      return "TRUE";
    }
  }
}

sub verificar_ambiente() {
  #Retorna "0" si el ambiente está bien inicializado, "1" en caso contrario.
  if(verificar_variables_necesarias_para_poder_verificar_ambiente() &&
      verificar_script_verificador_de_ambiente() &&
      script_verificador_de_ambiente()) {
    print "Ambiente correcto.\n";
    return "TRUE";
  } else {
    return 0;
  }
}
