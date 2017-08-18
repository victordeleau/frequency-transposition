%{
Programme MatLab
Transposition fréquentielle d'un signal haute fréquence dans la bande audible via undersampling
NavalGroup - Victor Deleau - Start 040717 - Last 200717

Fonction à rajouter :
	- Lecture/Ecriture/ecoute de fichiers audio .wav pcm
	- Redirection d'erreur
%} 

% Ajout de fonctions

fprintf('\n');

disp ('----------------------------------------------------------------------------------------')
disp ('---------------- Transposition fréquentielle via sous-échantillonnage ------------------')
disp ('----------------------------------------------------------------------------------------')
fprintf('\n');

% Déclaration de variable

prompt = 'Mode démo (o/n) ?';
demo = input( prompt, 's' );

if strcmp(demo,'o') == 1 ;
	disp ('Lancement du mode démo :')
    disp ('Fmin = 80500 Hz')
    fmin = 80500;
    
    disp ('Fmiax = 81000 Hz')
    fmax = 81000;
    
    disp ('Fmincible = 200 Hz')
    fmincible = 200;
    
    disp ('Fmaxcible = 1000 Hz')
    fmaxcible = 1000;
    
    disp ('foffset = 0 Hz')
    foffset = 0;
    
    disp ('Coupure du filtre à 20000 Hz')
    f_LP = 20000;
    
    disp ('Chirp de synthèse, durée 1 seconde')
    synth_duree = 1; 	

    disp ('Frequence échantillonnage de 324000 Hz ')
    fs = 324000;

    bw = (fmax - fmin);

    fs = 4 * fmax;

else
    
	disp ('Lancement du mode manuel :')
    prompt = 'Fréquence Fmin ?';
    fmin = input( prompt );
    prompt = 'Fréquence Fmax ?';
    fmax = input( prompt );
    prompt = 'Fréquence minimale cible ? Il est recommandé de ne pas aller en dessous de 100 Hz';		% Pour le PDV
    fmincible = input( prompt );
    prompt = 'Fréquence maximale cible ? Il est recommandé de ne pas aller au delà de 5000 Hz';		% Pour le PDV
    fmaxcible = input( prompt );
    prompt = 'Offset fréquentiel ?';
    foffset = input( prompt );

    %disp ('Signal de synthèse (1) ou fichier audio .wav (2)  ?')
    %signal_choix = input( prompt );
    signal_choix = 1;
    if signal_choix == 1
        prompt = 'Durée du signal de synthèse  ?';
        synth_duree = input( prompt );

        bw = (fmax - fmin);

        fs = 4 * fmax;

        if fs < (2*fmax)
            disp ('ATTENTION : Fe < 2*fmax , risque d aliasing')
        end
    end 

    if signal_choix == 2
        disp ('Le programme ne gère pas encore la lecture de fichier .wav')
        % PARTIE WAVE INPUT TODO %
    end

    if signal_choix ~= (1|2)
        disp ('Erreur : Veuillez retourner un entier valide.')
    end

    prompt = 'Fréquence de coupure du filtre (20000 maximum)  ?';
    f_LP = input(prompt);
    if f_LP > 20000;
            disp ('Erreur : Fréquence de coupure supérieur à 20 000 Hertz')
    end

end

    
prompt = 'Dessiner le signal d origine (o/n) ?';
plot_origin = input(prompt, 's');
if (strcmp(plot_origin,'o') | strcmp(plot_origin,'n')) == 0
	disp ('Erreur : Veuillez saisir oui (o) ou non (n)')
end

prompt = 'Dessiner le signal final (o/n) ?';
plot_final = input(prompt, 's');
if (strcmp(plot_final,'o') | strcmp(plot_final,'n')) == 0
	disp ('Erreur : Veuillez saisir oui (o) ou non (n)')
end

prompt = 'Dessiner le spectre initial (o/n) ?';
plot_spectre_initial = input(prompt, 's');
if (strcmp(plot_spectre_initial,'o') | strcmp(plot_spectre_initial,'n')) == 0
	disp ('Erreur : Veuillez saisir oui (o) ou non (n)')
end

prompt = 'Dessiner le spectre final (o/n) ?';
plot_spectre_final = input(prompt, 's');
if (strcmp(plot_spectre_final,'o') | strcmp(plot_spectre_final,'n')) == 0
	disp ('Erreur : Veuillez saisir oui (o) ou non (n)')
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Traitement du Signal

    t = 0:(1/(fs)):synth_duree;
	% Création d'un signal type chirp
	x = chirp(t,fmin,synth_duree,fmax, 'linear');
    X = x + 100*randn(1, length(x));


%{
prompt = 'Dessiner la fonction de transfert du filtre LP (o/n) ?';
plot_filter = input(prompt, 's');
if (strcmp(plot_filter,'o') | strcmp(plot_filter,'n')) == 0
	disp ('Erreur : Veuillez saisir oui (o) ou non (n)')
end

if strcmp(plot_filter,'o') == 1
    sos = zp2sos(z,p,k);
    hfvt = fvtool(sos, 20000, 'Analysis', 'freq');
    legend(hfvt,'ZPK Design')
end
%}
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Undersampling

kmax = fmax / bw;
fs_under = 2 * bw
e = 2;

% On trouve fs_under minimal sans repliement de spectre
while e <= kmax
    
    inf = (2 * fmax) / e;
    sup = (2 * fmin) / (e - 1);
    pas = bw / 100;

    if (fs_under <= inf) || (fs_under >= sup)
        fs_under = fs_under + pas;
    else
        break
    end
    
    e = e + 1;
end

% On cree le signal d'origine
N = fs * synth_duree;
t = 0:(1/fs):(fs/N);
x = chirp(t,(fmax-bw),(fs/N),fmax, 'linear');

% Ajout de bruit blanc
X = x + 0.2*randn(1, length(x));

% On sous-echantillonne
under_ratio = ceil(fs / fs_under)
if under_ratio%2 == 0
    under_ratio = under_ratio + 1;  % on veut un ratio impair
end
Y = downsample(X,under_ratio);

[p,q] = rat(48000/fs_under,0.0001);
Z = resample(Y,p,q);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Création du filtre

%{
fc = ((fmax-fmin + fmincible)/fmax);
n = 9;
[z,p,k] = butter(n,fc);
[b,a] = zp2tf(z,p,k);    % Convertion du model zpk vers transfer fonction

% Application du filtre
Z = filter(b,a,X);
% Z = filtfilt(b,a,C);      % Zero phase filtering
%}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% X Plotting

temp_size = size(X,2);
t_origin = 1/temp_size : 1/temp_size : 1;

if strcmp(plot_origin,'o') == 1
	figure;
	plot (t_origin,X,'linewidth', 0.5);
	title ('Signal origine');
	xlabel('Temps (s)');
	legend('Signal origine');
	grid on;
	axis ([0 0.1 -1.5 1.5  ]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Z Plotting

temp_size = size(Z,2);
t_final = 1/temp_size:1/temp_size:1 ;

if strcmp(plot_final,'o') == 1
	figure;
	plot (t_final,Z,'linewidth', 0.5);
	title ('Signal undersamplé');
	xlabel('Temps (s)');
	legend('Signal undersamplé');
	grid on;
    axis([0 0.1 -1.5 1.5])     % Mise à l'échelle du graphique
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Visualisation du spectre de sortie

% Spectre initial
if strcmp(plot_spectre_initial,'o') == 1

    L = synth_duree * fs ;
    T = 1/(fs) ;
    t_initial = (0:L-1)*T;

    h_hann = hann(size(X,2));
    X_fft = fft(X .* h_hann.');

    P2 = abs(X_fft/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);

    f = fs *(0:(L/2))/L;

    figure;
    plot(f,P1);
    title('Spectre signal origin');
    xlabel('f (Hz)');
    ylabel('|P1(f)|');
    axis([0 1000 0 0.05 ]);
    
end

% Spectre final
if strcmp(plot_spectre_final,'o') == 1

    L = synth_duree * 48000 ;
    T = 1/(48000) ;
    t_final = (0:L-1)*T;

    h_hann = hann(size(Z,2));
    Z_fft = fft(Z .* h_hann.');

    P2 = abs(Z_fft/L);
    P1 = P2(1:floor(L/2+1));
    P1(2:end-1) = 2*P1(2:end-1);

    f = 48000 *(0:(L/2))/L;

    figure;
    plot(f,P1);
    title('Spectre signal final');
    xlabel('f (Hz)');
    ylabel('|P1(f)|');
    axis([0 1000 0 0.05 ]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ecoute du résultat

% downsample_ratio = ceil( fs_under / 48000);
% Y_downsample = downsample(Y,downsample_ratio);

prompt = 'Traitement terminé. Voulez vous écouter le résultat (o/n)?';
ecoute = input(prompt, 's');
if (strcmp(ecoute,'o') | strcmp(ecoute,'n')) == 0
	disp ('Erreur : Veuillez saisir oui (o) ou non (n)')
end

if strcmp(ecoute,'o') == 1
	soundsc(real(Z),48000);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Export au format wave

%{
prompt = 'Export wave PCM (o/n)?';
pcm = input(prompt, 's');
if (strcmp(pcm,'o') | strcmp(pcm,'n')) == 0
	disp ('Erreur : Veuillez saisir oui (o) ou non (n)')
end

if strcmp(pcm,'o') == 1
    audiowrite('export_pdv.wav',real(Z_downsample),48000);
end
%}

%%% END %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

empty = '';
input(empty, 's');

% Fermeture des fenêtres ouvertes
close all

disp('Exécution terminé.')






