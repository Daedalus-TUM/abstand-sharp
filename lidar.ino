/*
CODE zur AUSLESUNG des ABSTANDSSENSORS

verfeinerte Stufen, Berücksichtigung der Stärke des IR-Streulichtes
Externe Stromversorgung: 5V Netzteil, kollektives GND
SHARP-Abstandssensor: Vcc auf 5V; Vo auf A0; GND
PHOTODIODE: Anode auf A1; GND
SERVO_WAAGRECHT: rot auf 5V extern; gelb auf digi9; braun=GND
SERVO_SENKRECHT: rot auf 5V extern; gelb auf digi10; braun=GND
SCHALTER: 5V Arduino; digi2; GND
*/


#include <Servo.h>

//PINBELEGUNG:
#define sensorpin A0
#define diodenpin A1
#define servo_waag_pin 9
#define servo_senk_pin 10
#define pbpin 2






//Für die Ausgabe der Nullen:
unsigned long sprungzeitpunkt=0;
int auto_off_time=15000;


//Deklarationen und Initialisierungen der Servos:
Servo servo_waag;
Servo servo_senk;

int anz_winkel_waag=30;
int anz_winkel_senk=30;

int winkel_waag=180;
int delta_winkel_waag=180/anz_winkel_waag;
int winkel_waag_ausgabe=0;
int flag_waag=0;
int flag_anfang=1;

int winkel_senk=180;
int delta_winkel_senk=180/anz_winkel_senk;
int winkel_senk_ausgabe=0;
int flag_senk=0;


//Dekarationen und Initialisierungen zur Abstands
int werte[3];
int anzwerte=3;

int anzIRwerte=5;
int ausgabe[35]={15,16,17,18,19,20,22,24,26,28,30,32,34,36,38,40,45,50,55,60,65,70,75,80,85,90,95,100,110,120,130,140,150,170,200};

int minwertvektor[3];     //kleinster Wert=1  AUCH HIER ANZAHL DER WERTE AUSTAUSCHEN!
int maxwertvektor[3];     //groesster Wert=1  AUCH HIER ANZAHL DER WERTE AUSTAUSCHEN!
int gleichwertvektor[3];  //Anzahl der vorkommenden Werte




//____________________________________________________________________________________________________
void setup()
{
  Serial.begin(9600);
  
  servo_waag.attach(servo_waag_pin); //SERVO Pin-Zuweisung
  servo_waag.write(winkel_waag);
  servo_senk.attach(servo_senk_pin);
  servo_senk.write(winkel_senk);
  
  pinMode(pbpin,INPUT);
  null_ausgabe();
}




//____________________________________________________________________________________________________
void loop()
{
  int i=0;
  int j=0;
  
  int redsumme=0;
  int gesamtsumme=0;
  int gesamtmittel=0;
  int redmittel=0;
  int voltage=0;             //eingelesene Spannung
  int distanz=0;             //Entfernung in cm
  
  int IRmittel=0;
  
  int kleinster=0;           //zaehler: wenn kleinster==anzwerte-1: werte[i]=kleinster eingelesener Wert
  int groesster=0;           //zaehler: wenn groesster==anzwerte-1: werte[i]=groesster eingelesener Wert
  int gleich=1;              //zaehler: wie oft tritt werte[i] auf?
  
  
  
  
  
  //Abstandsdaten werden eingelesen und ins Array 'werte' abgespeichert
  for(i=0;i<anzwerte;i++)
  {
    werte[i]=analogRead(sensorpin);
    gesamtsumme=gesamtsumme+werte[i];
    //Serial.print(werte[i]);
    //Serial.print(" ");
    
    if (i==(anzwerte-1))
    {
      break;
    }
    
    delay(50);
  }
  
  
  for (i=0;i<anzwerte;i++)
  {
    for (j=0;j<i;j++)
    {
      if (werte[i]<werte[j])
      {
        kleinster++;
      }
      else if (werte[i]>werte[j])
      {
        groesster++;
      }
      else if (werte[i]==werte[j])
      {
        gleich++;
      }
    }
    
    for (j=(i+1);j<anzwerte;j++)
    {
      if (werte[i]<werte[j])
      {
        kleinster++;
      }
      else if (werte[i]>werte[j])
      {
        groesster++;
      }
      else if (werte[i]==werte[j])
      {
        gleich++;
      }
    }
    
    minwertvektor[i]=kleinster;
    maxwertvektor[i]=groesster;
    gleichwertvektor[i]=gleich;
    
    kleinster=0;
    groesster=0;
    gleich=1;
  }
  
  
  j=0;                                    //Ruecksetzung von j
  
  for (i=0;i<anzwerte;i++)                //groesster und kleinster Wert werden auf Null gesetzt 
  {
    if (minwertvektor[i]==(anzwerte-1))
    {
      werte[i]=0;
    }
    
    if (maxwertvektor[i]==(anzwerte-1))
    {
      werte[i]=0;
    }
    
    if (werte[i]!=0)                      //Anzahl der Nicht-Null-Elemente von werte[]
    {
      j++;
    }
    
    redsumme=redsumme+werte[i];
  }
  
  gesamtmittel=gesamtsumme/anzwerte;
  redmittel=redsumme/j;
  
  
  //Einlesen des Streulichtwertes durch Photodiode:
  
  for (i=0;i<anzIRwerte;i++)
  {
    IRmittel=IRmittel+analogRead(diodenpin);
    delayMicroseconds(300);
  }
  
  IRmittel=IRmittel/anzIRwerte;
  
  
  i=diskretisierer(redmittel);
  
  
    
  //Umrechnung der Winkel in vom Matlab-Programm verwendbare Daten:
  
  winkel_waag_ausgabe=180-winkel_waag;
  winkel_senk_ausgabe=180-winkel_senk;
  
  //Ausgaben:
  Serial.print(winkel_waag_ausgabe);
  Serial.print(" ");
  Serial.print(winkel_senk_ausgabe);
  Serial.print(" ");
  Serial.println(ausgabe[i]);
  
  
  
  int flag_schalter=schalter();
  
  if (flag_schalter==0)
  {
    sprungzeitpunkt=millis();
    null_ausgabe();
  }
  
  
  
  //Logik zur Servobewegung:
  
  if ((winkel_waag==0)&&(flag_senk==0))
  {
    delta_winkel_waag=-delta_winkel_waag;
    flag_waag=1;
  }
  else if ((winkel_waag==180)&&(flag_senk==0))
  {
    delta_winkel_waag=-delta_winkel_waag;
    flag_waag=1;
  }
  
  flag_senk=0;
  
  
  if (flag_anfang==1)
  {
    flag_waag=0;
    flag_anfang=0;
  } 
  
  
  if (flag_waag==0)
  {
    winkel_waag=winkel_waag+delta_winkel_waag;
  }
  else if (flag_waag==1)
  {
    if (winkel_senk==0)
    {
      delta_winkel_senk=-delta_winkel_senk;
    }
    else if (winkel_senk==180)
    {
      delta_winkel_senk=-delta_winkel_senk;
    }
    
    winkel_senk=winkel_senk+delta_winkel_senk;
    flag_waag=0;
    flag_senk=1;
  }
  
  
  //Hier: Servobefehl 1
  servo_waag.write(winkel_waag);
  
  //Hier: Servobefehl 2
  servo_senk.write(winkel_senk);
  
}




//____________________________________________________________________________________________________
//Diskretisierung und Umwandlung in Zentimeterangabe:

int diskretisierer(int r)
{
  int i=0;
  
  if (r>537)
  {
    i=0;                      //15
  }
  else if ((r<=537)&&(r>530))
  {
    i=1;                      //16
  }
  else if ((r<=530)&&(r>519))
  {
    i=2;                      //17
  }
  else if ((r<=519)&&(r>512))
  {
    i=3;                      //18
  }
  else if ((r<=512)&&(r>500))
  {
    i=4;                      //19
  }
  else if ((r<=500)&&(r>487))
  {
    i=5;                      //20
  }
  else if ((r<=487)&&(r>467))
  {
    i=6;                      //22
  }
  else if ((r<=467)&&(r>445))
  {
    i=7;                      //24
  }
  else if ((r<=445)&&(r>423))
  {
    i=8;                      //26
  }
  else if ((r<=423)&&(r>410))
  {
    i=9;                      //28
  }
  else if ((r<=410)&&(r>382))
  {
    i=10;                     //30
  }
  else if ((r<=382)&&(r>361))
  {
    i=11;                     //32
  }
  else if ((r<=361)&&(r>343))
  {
    i=12;                     //34
  }
  else if ((r<=343)&&(r>326))
  {
    i=13;                     //36
  }
  else if ((r<=326)&&(r>311))
  {
    i=14;                     //38
  }
  else if ((r<=311)&&(r>287))
  {
    i=15;                     //40
  }
  else if ((r<=287)&&(r>256))
  {
    i=16;                     //45
  }
  else if ((r<=256)&&(r>233))
  {
    i=17;                     //50
  }
  else if ((r<=233)&&(r>214))
  {
    i=18;                     //55
  }
  else if ((r<=214)&&(r>197))
  {
    i=19;                     //60
  }
  else if ((r<=197)&&(r>181))
  {
    i=20;                     //65
  }
  else if ((r<=181)&&(r>169))
  {
    i=21;                     //70
  }
  else if ((r<=169)&&(r>164))
  {
    i=22;                     //75
  }
  else if ((r<=164)&&(r>152))
  {
    i=23;                     //80
  }
  else if ((r<=152)&&(r>144))
  {
    i=24;                     //85
  }
  else if ((r<=144)&&(r>136))
  {
    i=25;                     //90
  }
  else if ((r<=136)&&(r>130))
  {
    i=26;                     //95
  }
  else if ((r<=130)&&(r>122))
  {
    i=27;                     //100
  }
  else if ((r<=122)&&(r>112))
  {
    i=28;                     //110
  }
  else if ((r<=112)&&(r>104))
  {
    i=29;                     //120
  }
  else if ((r<=104)&&(r>95))
  {
    i=30;                     //130
  }
  else if ((r<=95)&&(r>88))
  {
    i=31;                     //140
  }
  else if ((r<=88)&&(r>81))
  {
    i=32;                     //150
  }
  else if ((r<=81)&&(r>70))
  {
    i=33;                     //170
  }
  else if (r<=70)
  {
    i=34;                     //200
  }
  
  return i;
}




//____________________________________________________________________________________________________
//Ausgabe der Nullen:
void null_ausgabe()
{
  int wert=0;
  while(1)
  {
    Serial.print(wert);
    Serial.print(" ");
    Serial.print(wert);
    Serial.print(" ");
    Serial.println(wert);
    delay(110);
    
    int flag_schalter=schalter();
    
    //Wird der Schalter betaetigt, gebe 4 Nullen aus, springe in die Loop:
    if (flag_schalter==1)
    {
      Serial.print(wert);
      Serial.print(" ");
      Serial.print(wert);
      Serial.print(" ");
      Serial.print(wert);
      Serial.print(" ");
      Serial.println(wert);
      break;
    }
    
    //Zur endgültigen Funktionsbeendigung in Matlab gebe 5 Nullen aus:
    if (millis()>(sprungzeitpunkt+auto_off_time))
    {
      Serial.print(wert);
      Serial.print(" ");
      Serial.print(wert);
      Serial.print(" ");
      Serial.print(wert);
      Serial.print(" ");
      Serial.print(wert);
      Serial.print(" ");
      Serial.println(wert);
      
      while(1)
      {}
    }
  }
}



//____________________________________________________________________________________________________
//Schalterentprellung:
int schalter()
{
  int schalt=0;
  
  for (int i=0;i<5;i++)
  {
    schalt=schalt+digitalRead(pbpin);
    delay(1);
  }
  
  if (schalt<3)
  {
    return 0;
  }
  else
  {
    return 1;
  }
}


