function Plot_Arduino22


%eingelesene Werte waag: -90<winkel_waag<90 Grad; Anfangswert vom Servo bei
%-90Grad
%eingelesene Werte senk:  0<winkel_senk<180 Grad; Anfangswert vom Servo bei
%0




%__________________________________________________________________________
%Initialiserungen:

%Waagrechte Winkel:
anz_winkel_waag=31;
delta_winkel_waag=-180/anz_winkel_waag;             %Winkel pro Entfernungswert, waagrecht
winkel_waag_start=90+delta_winkel_waag/2;           %Anfangswert für den waagrechten Winkel
winkel_waag=winkel_waag_start;                      %Anfangswert für den waagrechten Winkel
z_waag=1;                                           %Zähler für waagrechten Winkel
flag_waag=0;
flag_anfang=1;

%Senkrechte Winkel:
anz_winkel_senk=31;
delta_winkel_senk=180/anz_winkel_senk;              %Winkel pro Entfernungswert, senkrecht
winkel_senk_start=delta_winkel_senk/2;              %Anfangswert für den senkrechten Winkel  
winkel_senk=winkel_senk_start;                      %Anfangswert für den senkrechten Winkel
z_senk=1;                                           %Zähler für senkrechten Winkel
flag_senk=0;


anz_winkel_schritte=anz_winkel_waag*anz_winkel_senk;
obere_grenze=anz_winkel_schritte*10;                 %Schleifendurchgänge
plot_zaehler=1;                                     %Laufende Nummer des aktuellen Plots

%Zur Drehung in die richtige Ansicht:
a=(3*pi)/2;                                         %Zur Drehung um die y-Achse
drehmatrix=[cos(a) 0 sin(a);0 1 0;-sin(a) 0 cos(a)];

ent_mat=ones(anz_winkel_senk,anz_winkel_waag);      %Matrix mit den Entfernungen
plot_mat_punkt=zeros(anz_winkel_senk,anz_winkel_waag);      % Matrix mit allen geplotteten Punkten
punkte_mat=zeros(anz_winkel_schritte,3);            %Matrix mit allen berechneten Koordinatenpunkten

stand_rad=20;                                      %Radius der Standard-Kugel
ent_mat=ent_mat*stand_rad;                          %Zur Erstellung der Standardkugel mit Radius 10

anz_polygone=(anz_winkel_senk-1)*(anz_winkel_waag-1);
poly_plot_vek=zeros(1,anz_polygone);                %Zeilenvektor mit allen Polygon-Plots
z_polygon=1;                                        %Polygon-Zähler

betr_poly_vek=ones(1,anz_winkel_schritte);          %Gibt jeweils die Spalte an, in die die nächste Polygon-Nummer geschrieben wird
betr_poly_mat=zeros(anz_winkel_schritte,4);         %Matrix mit Info, welche Polygone vom Punkt xy bestimmt werden
eckpunkt_mat=zeros(anz_polygone,4);                 %Speichert pro Polygon: (Ecke1,Ecke2,Ecke3,Ecke4)





%__________________________________________________________________________
%Graphikvorbereitungen:

plot3(0,0,0,'k.');
axis([-200,200,-200,200,-200,200]); hold on; grid;
view(30,30);
xlabel('x');
ylabel('y');
zlabel('z');

x=(-200:200);
y=(-200:200);
z=(-200:200);

plot3(x,0,0)         %x-Achse
plot3(0,y,0)         %y-Achse
plot3(0,0,z)         %z-Achse





%__________________________________________________________________________
%Erstellung der Standard-Kugel in Punkten:

for j=(1:anz_winkel_schritte)
    
    %Winkelbewegung waagrecht:
    if (flag_anfang~=1)
        if (winkel_waag+delta_winkel_waag)>=90
            flag_waag=1;
            z_waag=1;
        elseif (winkel_waag+delta_winkel_waag)<=-90
            flag_waag=1;
            z_waag=1;
        end
    end
    
    
    if ((flag_waag==0)&&(flag_anfang~=1))
        winkel_waag=winkel_waag+delta_winkel_waag;
        z_waag=z_waag+1;
    end
    
    %Winkelbewegung senkrecht:
    if flag_waag==1
        
        if z_senk==anz_winkel_senk
            z_senk=1;
            flag_senk=1;
            winkel_senk=winkel_senk_start;
        else
            winkel_senk=winkel_senk+delta_winkel_senk;
            z_senk=z_senk+1;
        end
        
        if flag_senk==1
            winkel_waag=winkel_waag_start;
            flag_senk=0;
            
            if mod(anz_winkel_senk,2)~=0
                delta_winkel_waag=-delta_winkel_waag;
            end
        end
        
        delta_winkel_waag=-delta_winkel_waag;
        flag_waag=0;
    end
    
    winkel_waag_rad=winkel_waag*pi/180;
    winkel_senk_rad=winkel_senk*pi/180;
    
    %Punkte werden berechnet und geplottet:
    [x_0,y_0,z_0]=sph2cart(winkel_senk_rad,winkel_waag_rad,ent_mat(z_senk,z_waag));
    x_vek=[x_0,y_0,z_0];
    x_vek=(drehmatrix*x_vek')';
    
    punkte_mat(plot_zaehler,1)=x_vek(1);            %Speichern der einzelnen
    punkte_mat(plot_zaehler,2)=x_vek(2);            %Koordinaten in die
    punkte_mat(plot_zaehler,3)=x_vek(3);            %Matrix 'punkte_mat'
    
    plot_mat_punkt(z_senk,z_waag)=plot3(x_vek(1),x_vek(2),x_vek(3),'k');
    
    plot_zaehler=plot_zaehler+1;
    flag_anfang=0;
    
end



%__________________________________________________________________________
%Erstellung der Polygone der Standard-Kugel:

eckpunkt_1=1;       %Gibt die Nummer des ersten Eckpunkts jedes Polygons an
z_senk=1;
z_waag=1;

%Polygone zwischen den einzelnen Punkten werden geplottet:
for i=(1:anz_polygone)
    
    %Erstellung der Vektoren zu den Eckpunkten:
    eckpunkt_2=eckpunkt_1+1;
    eckpunkt_4=(z_senk+1)*anz_winkel_waag-(z_waag-1);
    eckpunkt_3=eckpunkt_4-1;
    
    vek_1=punkte_mat(eckpunkt_1,:);
    vek_2=punkte_mat(eckpunkt_2,:);
    vek_3=punkte_mat(eckpunkt_3,:);
    vek_4=punkte_mat(eckpunkt_4,:);
    
    X=[vek_1(1),vek_2(1),vek_3(1),vek_4(1)];
    Y=[vek_1(2),vek_2(2),vek_3(2),vek_4(2)];
    Z=[vek_1(3),vek_2(3),vek_3(3),vek_4(3)];
    
    Farbe=stand_rad/200*255;
    
    poly_plot_vek(1,z_polygon)=fill3(X,Y,Z,[255/255 Farbe/255 0/255]);
    
    betr_poly_mat(eckpunkt_1,betr_poly_vek(1,eckpunkt_1))=z_polygon;
    betr_poly_mat(eckpunkt_2,betr_poly_vek(1,eckpunkt_2))=z_polygon;
    betr_poly_mat(eckpunkt_3,betr_poly_vek(1,eckpunkt_3))=z_polygon;
    betr_poly_mat(eckpunkt_4,betr_poly_vek(1,eckpunkt_4))=z_polygon;
    
    betr_poly_vek(1,eckpunkt_1)=betr_poly_vek(1,eckpunkt_1)+1;
    betr_poly_vek(1,eckpunkt_2)=betr_poly_vek(1,eckpunkt_2)+1;
    betr_poly_vek(1,eckpunkt_3)=betr_poly_vek(1,eckpunkt_3)+1;
    betr_poly_vek(1,eckpunkt_4)=betr_poly_vek(1,eckpunkt_4)+1;
    
    eckpunkt_mat(z_polygon,1)=eckpunkt_1;
    eckpunkt_mat(z_polygon,2)=eckpunkt_2;
    eckpunkt_mat(z_polygon,3)=eckpunkt_3;
    eckpunkt_mat(z_polygon,4)=eckpunkt_4;
    
    z_polygon=z_polygon+1;
    
    if (mod(eckpunkt_1,anz_winkel_waag)==(anz_winkel_waag-1))
        eckpunkt_1=eckpunkt_1+2;
        z_senk=z_senk+1;
        z_waag=1;
    else
        eckpunkt_1=eckpunkt_1+1;
        z_waag=z_waag+1;
    end
end

betr_poly_vek=betr_poly_vek-1;          %Bei der vorherigen Schleife wurde stets pro Element 1 zu viel addiert





%__________________________________________________________________________
%Herstellung der Verbindung an den USB-Port:
s1=serial('/dev/ttyUSB2');
fopen(s1);




%__________________________________________________________________________
%Warteschleife vor Beginn des Plots:
while 1
    Datenblock=fscanf(s1,'%d');
    groesse=size(Datenblock);
    
    if (groesse(1,1)==4)
        break;
    end
end


%__________________________________________________________________________
%Entfernungen werden eingelesen und die Polygone aktualisiert:

flag_anfang=1;
plot_zaehler=1;


for i=(1:obere_grenze)
    
    
    %Speicherung der Matrix-Indizes vom Vorgängerplot
    z_waag_letzter=z_waag;
    z_senk_letzter=z_senk;
    
    
    %----------------------------------------------------------------------
    %Winkelbewegung:
    %Winkelbewegung waagrecht:
    if (winkel_waag+delta_winkel_waag)>=90
        flag_waag=1;
        z_waag=1;
    elseif (winkel_waag+delta_winkel_waag)<=-90
        flag_waag=1;
        z_waag=1;
    end
    
    
    if flag_waag==0
        %winkel_waag=winkel_waag+delta_winkel_waag;
        z_waag=z_waag+1;
    end
    
    %Winkelbewegung senkrecht:
    if flag_waag==1
        
        if z_senk==anz_winkel_senk
            z_senk=1;
            flag_senk=1;
            %winkel_senk=winkel_senk_start;
        else
            %winkel_senk=winkel_senk+delta_winkel_senk;
            z_senk=z_senk+1;
        end
        
        if flag_senk==1
            %winkel_waag=winkel_waag_start;
            flag_senk=0;
            
            if mod(anz_winkel_senk,2)~=0
                delta_winkel_waag=-delta_winkel_waag;
            end
        end
        delta_winkel_waag=-delta_winkel_waag;
        flag_waag=0;
    end
    
    
    
    %----------------------------------------------------------------------
    %weitere Werte werden eingelesen:
    Datenblock=fscanf(s1,'%d');
    
    
    
    %----------------------------------------------------------------------
    %Bedingter Aufenthalt in einer Warteschleife:
    if (Datenblock(1,1)==0)&&(Datenblock(2,1)==0)&&(Datenblock(3,1)==0)
        while 1
            Datenblock=fscanf(s1,'%d');
            groesse=size(Datenblock);

            
            if (groesse(1,1)==4)
                Datenblock=fscanf(s1,'%d');
                break;
            elseif (groesse(1,1)==5)
                disp('Ende Gelände');
                fclose(s1);
                delete(s1);
                clear s1;
                hold off;
                return;
            end
        end
    end
    
    
    
    winkel_waag_ard=Datenblock(1);
    winkel_senk_ard=Datenblock(2);
    akt_ent=Datenblock(3);
    
    winkel_waag=-winkel_waag_ard+90;
    %winkel_waag=winkel_waag-(delta_winkel_waag/2)*(winkel_waag/90);
    
    winkel_senk=winkel_senk_ard;
    %if (winkel_senk<=90)
    %    winkel_senk=winkel_senk+(delta_winkel_senk/2)*((90-winkel_senk)/90);
    %else
    %    winkel_senk=winkel_senk-(delta_winkel_senk/2)*((winkel_senk-90)/90);
    %end
    
    
    
    %Übernehme gültigen Wert in die Entfernungsmatrix:
    ent_mat(z_senk,z_waag)=akt_ent;
    
    winkel_waag_rad=winkel_waag*pi/180;
    winkel_senk_rad=winkel_senk*pi/180;
    
    
    
    
    %----------------------------------------------------------------------
    %Neuer Punkt-Plot:
    
    %Ersetze letzten '+'-Plot durch neue Farbe und '.':
    if (flag_anfang==0)
        delete(plot_mat_punkt(z_senk_letzter,z_waag_letzter));
        plot_mat_punkt(z_senk_letzter,z_waag_letzter)=plot3(x_vek(1),x_vek(2),x_vek(3),'c.');
    end
    
    flag_anfang=0;

    
    %Überschreibe alten Punkt-Plot durch neuen Punkt:
    delete(plot_mat_punkt(z_senk,z_waag));
    
    [x_0,y_0,z_0]=sph2cart(winkel_senk_rad,winkel_waag_rad,ent_mat(z_senk,z_waag));
    x_vek=[x_0,y_0,z_0];
    x_vek=(drehmatrix*x_vek')';
    
    punkte_mat(plot_zaehler,1)=x_vek(1);            %Speichern der einzelnen
    punkte_mat(plot_zaehler,2)=x_vek(2);            %Koordinaten in die
    punkte_mat(plot_zaehler,3)=x_vek(3);            %Matrix 'punkte_mat'
    
    plot_mat_punkt(z_senk,z_waag)=plot3(x_vek(1),x_vek(2),x_vek(3),'ko');
    
    
    
    
        
    %----------------------------------------------------------------------
    %Lösche die alten betroffenen Polygone und erstelle die neuen:
    
    %poly_plot_vek(1,z_polygon)%Speicherung des Polygon-Plots
    %betr_poly_vek(1,eckpunkt_1)%Speicherung der Anzahl der betroffenen Polygone pro Punkt
    %betr_poly_mat(eckpunkt_1,betr_poly_vek(1,eckpunkt_1))%Speicherung der laufenden Nummern der pro Punkt betroffenen Polygone
    
    
    
    betr_poly_zaehler=1;
    
    for j=(1:betr_poly_vek(1,plot_zaehler))
        
        %Lösche:
        delete(poly_plot_vek(1,betr_poly_mat(plot_zaehler,betr_poly_zaehler)));
        
        
        
        %Beziehe neue Eckpunkte:
        
        vek_1=punkte_mat(eckpunkt_mat(betr_poly_mat(plot_zaehler,betr_poly_zaehler),1),:);
        vek_2=punkte_mat(eckpunkt_mat(betr_poly_mat(plot_zaehler,betr_poly_zaehler),2),:);
        vek_3=punkte_mat(eckpunkt_mat(betr_poly_mat(plot_zaehler,betr_poly_zaehler),3),:);
        vek_4=punkte_mat(eckpunkt_mat(betr_poly_mat(plot_zaehler,betr_poly_zaehler),4),:);
        
        X=[vek_1(1),vek_2(1),vek_3(1),vek_4(1)];
        Y=[vek_1(2),vek_2(2),vek_3(2),vek_4(2)];
        Z=[vek_1(3),vek_2(3),vek_3(3),vek_4(3)];
        
        %Farbe=akt_ent/200*255;
        Farbe=111;
        
        %h = patch(rand(5,1),rand(5,1),rand(5,1),'r');
        %set(h,'facealpha',.1)
        %set(h,'edgealpha',.5)
        
        
        %Erstelle:
        poly_plot_vek(1,betr_poly_mat(plot_zaehler,betr_poly_zaehler))=fill3(X,Y,Z,[255/255 Farbe/255 0/255]);
        alpha(0.5)
        betr_poly_zaehler=betr_poly_zaehler+1;
    end
    
    
    
    if (plot_zaehler==anz_winkel_schritte)
        plot_zaehler=1;
    else
        plot_zaehler=plot_zaehler+1;
    end
    
end





%__________________________________________________________________________
%Verbindung zum USB-Port wird gelöscht:
hold off;
fclose(s1);
delete(s1);
clear s1;



















%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Abbruchbedingung:              %
abbruch=input('Abbrechen: ');   %
if (abbruch==1)                 %
    hold off;                   %
    return;                     %
end                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



