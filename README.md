# 8digits iOS SDK Kullanım Kılavuzu

## Kurulum
EightDigits-iOS-SDK-x.y.zip dosyası açılır. İçerisinden çıkan EightDigits dizini SDK'nın kendisidir. 8digits entegrasyonu yapmak istediğiniz projeyi Xcode'da açıp, *EightDigits* ve *Utility* klasörlerini projenize sürükleyip bırakmanız gereklidir. Bu esnada karşınıza çıkacak olan diyalog kutusunda *"Copy items into destination groupʼs folder (if needed)"* seçeneğinin seçili olduğundan emin olunuz. 

![Copying EightDigits](8Digits-iOS-SDK/raw/master/figures/figure1.png)

Kopyalama işlemi yapıldıktan sonra projeniz aşağıdaki gibi görünecektir. 

![Project Tree](DocumentImages/figure2.png)

EightDigits iOS SDK server ile iletişim için ASI Http kütüphanesini kullanmaktadır. Ayrıca serverside APIden dönen JSON içeriği parse edebilmek için de SBJSON kütüphanesini kullanmaktadır. Bu kütüphanelerin çalışabilmesi için bazı library'lerin link edilmesi gereklidir. 

Bu işlemi yapabilmek için sol taraftaki proje ağacında projenizin ismine tıklayıp, **Targets**'da projenize tıklayıp, **Build Phases** sekmesi altında **Link Binary With Libraries** içerisine aşağıdaki kütüphaneleri ekliyoruz. 

![Kütüphaneler](DocumentImages/figure3.png)

Ardından projenizi hemen build etmeye çalıştığınızda aşağıdaki ekrandaki gibi bir hata ile karşılaşabilirsiniz. 

![XML Build Hata Ekranı](DocumentImages/figure4.png)

Bu hata mesajını aşmak için **Build Settings** altında **Search Paths** içerisinde **User Header Search Paths** içerisine aşağıdaki iki satırı eklemek gereklidir. 

![Header Fix](DocumentImages/figure5.png)

Yukarıdaki işlemleri yaptıktan sonra build işlemini yaptığınızda projeniz sorunsuz bir şekilde derlenecektir. Kurulum tamamlanmıştır. 

## SDK'nın kullanımı.

Aşağıdaki örneklere devam edebilmek için AppDelegate.h dosyasında yeni bir EightDigitsClient tanımlanması gerekecektir. Örnek bir .h dosyası aşağıdaki gibidir. 

	#import <UIKit/UIKit.h>
	#import "EightdigitsClient.h"
	
	@interface AppDelegate : UIResponder <UIApplicationDelegate> {
		UINavigationController *navigationController;
		EightdigitsClient *eightdigitsClient;
	}
	
	@property (strong, nonatomic) UIWindow *window;
	@property (nonatomic, retain) EightdigitsClient *eightdigitsClient;
	@property (nonatomic, retain) UINavigationController *navigationController;
	
	@end

### Yeni bir session yaratmak
Uygulama açılırken tercihen AppDelegate içerisinde yeni bir 8digits session yaratmak gereklidir. Bu işlem aşağıdaki gibi yapılır. 

	self.eightdigitsClient = [[EightdigitsClient alloc] initWithUrlPrefix:@"http://tr-api.8digits.com" trackingCode:@"code"];
	[self.eightdigitsClient authWithUsername:@"username" password:@"password"];

Tracking Code, username ve password değerleri size daha önce tarafımızca verilmiş olmalıdır. Eğer bilmiyorsanız lütfen konuyla ilgili bir [ticket açınız](http://support.8digits.com). 

### Bir session sonlandırmak

8digits uzun süre cevap alamadığı sessionları otomatikman expire etme yeteneğine sahiptir. Bu nedenle session sonlandırmak zorunluluk olmamakla birlikte mümkün olan durumlarda yapılması salık verilir. 

	[self.eightdigitsClient endVisit];

### Yeni bir ekran ziyareti

Uygulamanız her NIB dosyası değiştirdiğinde veya yeni bir görsel ile ekran değiştirdiğini düşündüğünüz herhangi bir anda 8digits'e yeni bir ekran ziyareti kaydı gönderebilirsiniz. Bir UIViewController için *viewWillAppear:(BOOL) animated* metodu bu işlemi yapmak için çok ideal bir yerdir. 

	- (void)viewWillAppear:(BOOL)animated {
		self.hitCode = [self.eightdigitsClient newScreenWithTitle:@"Screen Title" path:@"/screen/path"];
	}

Yukarıda title ve path değişkenleri tamamen sizin istediğiniz gibi tanımlayabileceğiniz ekranlardır. Free text olup, sizin için anlaşılır olan herhangi bir bilgiyi gönderebilirsiniz. 

 newScreenWithTitle:: geriye NSString tipinde bir değer döndürecektir. Bu değer o anda ziyaret etmekte olduğunuz screen'in hitCode'udur. Bir hitCode sizin ziyaretiniz boyunca her bir ekranı ayrıştırmak için kullanılan bir değerdir. O ekranla işiniz bittiğinde ekrandan çıktığınızı da yine bu hitCode'u kullanarak belirtirsiniz. 

### Bir ekran ziyaretini sonlandırmak

Bir ekran ile işinizin bittiğini düşündüğünüz anda screen'i ziyaret ettiğinizi belirttiğiniz  anda size verilmiş olan hitCode'u kullanarak ekran ile ilişkinizi kopartabilirsiniz. Bu işlemi yapmak için bir UIViewController içerisinde *viewWillDissapear: (BOOL) animated* metodu ideal lokasyondur. 

	- (void)viewWillDisappear:(BOOL)animated {
    	[self.eightdigitsClient endScreenWithHitCode:self.hitCode];
	}

### Event iletmek

İstenilen herhangi bir anda programatik olarak 8digits'e bir event göndermek mümkündür. Bu event'ler istenilen sayıda ve çeşitlilikte olabilir. Örneğin bir gesture sonrasında, bir upload işlemi sonrasında veya bir butona basılması durumunda bir event gönderimi yapılabilir. 

Örneğin bir event aşağıdaki gibi gönderilebilir. 

	[self.eightdigitsClient eventWithKey:@"UploadBusinessCard" value:@"1" hitCode:self.hitCode];

### Score bilgisini almak

8digits'te her kullanıcının bir engagement score'u mevcuttur. Bu score o kullanıcının o hizmet veya servise ne kadar ilgili olduğunu gösteren akıllı bir metriktir. Bu değeri okumak için aşağıdaki metod kullanılabilir. 

	NSInteger score = [self.eightdigitsClient score];
	
### Badge listesini almak

8digits analytics platformunun yanısıra aynı zamanda pek çok oyun mekaniğini de beraberinde sunmaktadır. Bunlardan bir tanesi olan badge altyapısı, serverside'dan tanımlanabilen kurallar sonrasında ziyaretçilerin kazandıkları sanal objelerdir. 

Bir kişinin o esnada sahip olduğu badge listesini alabilmek için aşağıdaki gibi bir metod kullanılabilir. 

	NSArray *badges = [self.eightdigitsClient badges];
	
### ID'si bilinen bir badge'in imajını göstermek

Bir kullanıcının badge listesi alındığında o listedeki badge'lerin id'leri geriye dönecektir. ID'si bilinen bir badge'in ise resmini göstermek için aşağıdaki gibi bir kullanım mümkündür. 

	UIImage *image = [self.eightdigitsClient badgeImageForId:@"badgeId"];
