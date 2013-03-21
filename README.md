#8digits iOS API 1.0
  
8digits iOS API'si, iOS uygulamalarında kullanılmak üzere yazılmış Objective-C classlarından oluşan bir kütüphane niteliğindedir. API içerisinde `ED` prefixli classların yanında, uygulamaların akıcılığını korumak adına oluşturulmuş `UIKit` class kategorileri de bulunmaktadır. 

8digits API, dilendiği takdirde işlemlerin bir kısmını otomatize ederek geliştiricilere kolaylık sağlar. Bununla ilgili detaylı bilgiyi **Hit Otomatizasyonu** bölümünde bulabilirsiniz.

8digits API, kendi sınıflarının yanında [ASIHTTP](http://allseeing-i.com/ASIHTTPRequest/), [JSONKit](https://github.com/johnezang/JSONKit/) ve [Reachability](https://github.com/tonymillion/Reachability/) kütüphanelerini kullanır. 

##API Hakkında

8digits API'yi oluşturan bölümlere bir göz atalım.


###Visit

Uygulama her açıldığında bir visit oluşturulur ve bütün işlemler bu visit üzerinden yürür ve bir session içerisinde gruplandırılır. API authentikasyonu da bu visit üzerinden yapılır. 

Uygulama kapandığında visit de sonlanmalıdır.

Bir visit başlatmak için `Api Key`, `trackingCode` ve `URLPrefix` parametrelerine ihtiyaç vardır. Bu bilgileri 8digits profil ayarları bölümünde bulabilirsiniz.

###Visitor

Uygulama ilk kez açıldığında uygulamayı açan kullanıcıya bir `visitorID` verilir ve bu kullanıcı uygulamanızı her kullandığında cihazın sabit diskinde tutulan identifier ile tespit edilir. 

Kullanıcıyla ilgili bilgiler (kullanıcı badgeleri ve skoru gibi) indentifier üzerinden takip edilir. 8digits API, bu bilgiyi kendisi oluşturarak kontrol eder.

8digits API, cihazı kullanan kullanıcının badgelerine ve skoruna ulaşma imkanının yanında, kullanıcı skorunu istediğiniz kadar artırma ve azaltma imkanı da sağlar.

###Hit

Yeni bir ekran görüntülemesi yapılacağında o ekran için bir hit başlatmak gereklidir. Aynı anda birden fazla ekran aktif olabilir, yani yeni bir hit başlatmak için halihazırda aktif olan hitleri sonlandırmak gerekmez. Hit sonlanana kadar aktif olarak değerlendirilir.

Her hit, yani ekran için `title` ve `path` parametrelerine ihtiyaç vardır. Bu bilgiler free text olup, tamamen sizin ekranları birbirinden kolayca ayırt etmenize olanak sağlamak amacıyla bulunmaktadır.

###Event 

Bir ekrandaki herhangi bir düğmeye basma, touch gesture veya butona basma işlemi 8digits’e gönderilebilir. Bu sayede o ekranda olan biten herhangi bir işlemi track etme imkanınız olabilmektedir. Bu işlem için eventler kullanılmaktadır.

Yeni bir event gönderebilmek için bir adet key ve bir adet value’ya ihtiyacınız vardır. Bu key değerlerini unique tutarsanız yapılan işlemler birbiri ile karışmayacaktır.
Örneğin bir düğmeye basıldığında ve ürün incelenmeye alındığında key olarak `ProductWatch` value olarak da ürünün sizin taraftaki product id sini `L5308073` gönderebilirsiniz. Bu sayede hangi ürünün kaçar defa incelendiğini saatlik, günlük ve overall görebilme imkanınız olacaktır.

Uygulamalarda bir event kuşkusuz ki bir ekranda gerçekleşecektir. Eğer ekran için daha önceden bir hit oluşturulduysa gönderilen event bu [hit](#hit) ile ilişkilendirilebilir. Hiçbir hit ile ilişkilendirilmemiş eventler de tercih edilebilir.


##Entegrasyon

8digits API entegrasyonu için öncelikle API'nin bulunduğu <https://github.com/8Digits/8digits-iOS-API> Github sayfasından dosyaları indirin. .zip dosyası içerisinde 8digits klasörünü bulacaksınız.

Eğer uygulamanıza daha önceden eklenmiş [ASIHTTP](http://allseeing-i.com/ASIHTTPRequest/), [JSONKit](https://github.com/johnezang/JSONKit/) ve [Reachability](https://github.com/tonymillion/Reachability/) kütüphaneleri yoksa bunları 8digits klasörünün içerisindeki External kalsöründe bulabilirsiniz. 

###Kütüphaneleri Ekleme

8digits klasörünü tümüyle tutarak proje ekranındaki diğer dosyalarınızın arasına sürükleyin. Çıkan diyalog penceresinden *Copy items into destination group's folder* seçeneğinin ve proje targetlarınızın seçili olduğundan emin olun ve **Finish** butonuna tıklayın. 

![Dosyaları ekleyin](8Digits-iOS-SDK/raw/master/figures/figure0.png)

###ARC Desteği
`ASIHTTP` ve `JSONKit` kütüphaneleri Automatic Reference Counting (ARC) teknolojisini desteklemez. Eğer projenizde ARC'ı aktifleştirdiyseniz şu adımları uygulamanız gerekmektedir:

1. Xcode'da sol taraftaki listeden proje dosyasını seçin. 
2. Sağ taraftaki pencereden Targets bölümünüzden uygulamanızın targetını seçin.
3. Build Phases sekmesine geçin.
4. Compile sources bölümünü genişletin.
5. `ASIAuthenticationDialog.m` dosyasının üzerine çift tıklayın.
6. Açılan küçük pencereye `-fno-objc-arc` yazın ve entera basın.
7. *5.* ve *6.* işlemleri birer birer `ASIDataCompressor.m`, `ASIDataDecompressor.m`, `ASIDownloadCache.m`, `ASIFormDataRequest.m`, `ASIHTTPRequest.m`, `ASIInputStream.m`, `ASINetworkQueue` ve `JSONKit.m` dosyaları için yapın.

![image](8Digits-iOS-SDK/raw/master/figures/figure1.png)

Bu işlemleri yaptıktan sonra eklediğiniz kütüphaneler ARC için hazır hale gelecektir.

###Framework Ekleme

`ASIHTTP`, `Reachability` ve `JSONKit` kütüphanelerinin çalışabilmesi için bazı frameworklerin projenize eklenmesi gerekmektedir. Bu işlemi şu adımları uygulayarak yapabilirsiniz:

1. Xcode'da sol taraftaki listeden proje dosyasını seçin. 
2. Sağ taraftaki pencereden Targets bölümünüzden uygulamanızın targetını seçin.
3. Build Phases sekmesine geçin.
4. Link Binary With Libraries bölümünü genişletin.
5. Link Binary With Libraries bölümünde sol alttaki **+** butonuna basın.
6. Çıkan küçük pencereden `MobileCoreServices.framework`'ü seçin ve **Add** butonuna basın.
7. *5.* ve *6.* adımları `libz.dylib`, `SystemConfiguration.framework`, `CFNetwork.framework` ve `Security.framework` için uygulayın.

![image](8Digits-iOS-SDK/raw/master/figures/figure2.png)

Bu adımları uyguladıktan sonra kütüphaneler için gereken framework desteğini de sağlamış olacaksınız.

Bu aşamadan sonra 8digits API kullanıma hazır hale gelecektir.

##Kullanım

8digits API'yi hem 8digits klasörü içerisindeki `EightDigits.plist` dosyasını kullanarak hem de kodunuzun içerisinde `ED` prefixli 8digits nesneleriyle iletişim kurarak kullanabilirsiniz. 

Unutmayın ki `ED` prefixli 8digits nesneleriyle iletişim kurduğunuz her dosyanın başına bu nesnelerin header dosyalarını import etmeniz gerekmektedir. Bunun için dosyaların başına `#import EightDigits.h` satırını eklemeniz yeterlidir.

`EightDigits.plist` dosyasının içerisine yerleştireceğiniz bilgiler yazdığınız kodu büyük ölçüde azaltabileceği ve işin bir kısmını otomatize edebileceği gibi tamamen opsiyoneldir. Dilerseniz bu dosyayı hiç kullanmayabilirsiniz.

###Visit Oluşturma ve Sonlandırma

Uygulama açıldığı anda bir visit başlatmalı ve uygulama kapandığında bu visiti sonlandırmalısınız. Başlattığınız visiti sonlandırmazsanız 8digits sunucusu uzun süre işlem yapılmadığından sizin yerinize otomatik olarak bu visiti sonlandıracaktır.

Bu işlemi tercihen `AppDelegate` sınıfınızın, uygulama açıldığında çağırılan `application:didFinishLaunchingWithOptions:` metodunun içerisine şu kodu ekleyerek yapabilirsiniz:

```
[[EDVisit currentVisit] startWithApiKey:@"your-api-key"
							 trackingCode:@"your-tracking-code"
								urlPrefix:@"your-url-prefix"];
```

Eğer `EightDigits.plist` dosyasına `EDTrackingCode` keyine karşılık tracking code değerinizi ve `EDURLPrefix`keyine karşılık api URL prefix değerinizi girdiyseniz bu visit başlatma işlemini şu kod satırıyla da yapabilirsiniz.

```
[[EDVisit currentVisit] startWithApiKey:@"your-api-key"];
```

**Not:** Güvenlik sebeplerinden dolayı (bundle içerisindeki .plist dosyalarına doğrudan erişilebildiğinden) `Api Key` değerinizin .plist dosyasında saklanması **kesinlikle tavsiye edilmez.** 

Eğer kullanıcı adı ve şifrenizi herhangi bir şekilde uygulamanızın içerisinde _hardcoded_ olarak tutmak istemiyorsanız, _authentication_ işlemini kendi serverlarınız üzerinde yapıp 8digits API'ye sadece size dönen _auth token_'ı vererek visit başlatabilirsiniz. Bunun için elinizdeki _auth token_'ı string halinde `[[EDVisit currentVisit] startWithAuthToken:]` metoduna göndermeniz yeterlidir.

**Not:** 8digits API'nin yaptığı başarılı/başarısız işlemleri loglarda görmek isterseniz, visit oluşturduktan hemen sonra `[[EDVisit currentVisit] startLogging]` metodunu çağırın. Uygulamanın herhangi bir yerinde loglamayı sonlandırmak için `[[EDVisit currentVisit] stopLogging]` metodunu kullanabilirsiniz.

Uygulama genelinde kullanacağınız `EDVisit` nesnesine `[EDVisit currentVisit]` ile ulaşabilirsiniz. Bu visit nesnesini `[[EDVisit alloc] init]` şeklinde oluşturmanıza gerek yoktur. 8digits API bu işlemi kendisi yapar.

Başlatmış olduğunuz bu visiti yine `AppDelegate` nesnesinin uygulama kapandığında çağırılan metoduna şu kodu ekleyerek sonlandırabilirsiniz.

```
[[EDVisit currentVisit] end];
```

###Hit Oluşturma ve Sonlandırma

8digits API, içerisinde bulundurduğu `UIViewController` kategorisi sayesinde her `UIViewController` ve `UIViewController` alt sınıf nesnesinin bir `EDHit` tipinde `hit` değişkeni bulunur. Hit oluşturma ve sonlandırma işlemlerini, tavsiye edildiği şekilde `UIViewController` nesneleri içerisinde yapacaksanız bu değişkeni kullanabilirsiniz. `UIViewController` ekranı gösterildiğinde çağırılan `viewWillAppear:` metodunun içerisine şu kodu ekleyerek bu ekrana ait bir hit oluşturabilir ve başlatabilirsiniz:

```
[self.hit setTitle:@"screen-title" path:@"screen-path"];
[self.hit start];
```

`self.hit` nesnesini `[[EDHit alloc] init]` şeklinde oluşturmanız gerekmez. `UIViewController` sizin yerinize bu işlemi yapar. Tabi eğer bu işlemi bir `UIViewController` nesnesi içerisinde yapmıyorsanız kodunuzun şu şekilde olması gerekmektedir:

```
EDHit *hit = [[EDHit alloc] init];
[hit setTitle:@"screen-title" path:@"screen-path"];
[hit start];
```

Başlatmış olduğunuz bir hiti şu şekilde sonlandırabilirsiniz:

```
[self.hit end];
```

###Hit Otomatizasyonu

`EightDigits.plist` dosyasının içerisinde `EDHits` keyine karşılık bir dizi vardır. Bu dizinin içerisinde class isimleri ve bu classların `title` ve `path` değerleri bulunur. Dizinin her elemanı şu key-value çiftlerinden oluşur:

`EDClassName`: class-name  
`EDTitle`: class-screen-title  
`EDPath`: class-screen-path  
`EDAutomaticMonitoring`: boolean-value (`YES` ya da `NO`)

Buradaki `EDTitle` ve `EDPath` değerlerini girdiyseniz bu değerler, class ismini girdiğiniz `UIViewController` tarafından otomatik olarak `self.hit.title` ve `self.hit.path` değişkenlerine atanır. Bu durumda `viewWillAppear:` metodunuza, bu title ve path değerlerine sahip bir hit başlatmak için şu satırı yazmanız yeterlidir.

```
[self.hit start];
```

Eğer bir `UIViewController` classı için `EDAutomaticMonitoring` değeri `YES` ise bu class içerisinde hit başlatıp bitirmenize gerek yoktur. 8digits API, sizin yerinize bu classın `viewWillAppear:` ve `viewWillDisappear:` metotlarında hit başlatıp bitirir. 

###Event Gönderme

Gönderdiğiniz eventler bir hit ile ilişkili olabildiği gibi, herhangi bir hite bağlı olmayan eventler de gönderebilirsiniz. Bir `UIViewController` içerisinden, bu `UIViewController` ekranıyla ilişkili event göndermek için şu kodu yazmanız yeterlidir:

```
[self triggerEventWithValue:@"value1" forKey:@"key"];
```

Eğer kendi oluşturduğunuz bir hit üzerinden event göndermek isterseniz şu şekilde yapabilirsiniz:

```
EDEvent *event = [[EDEvent alloc] initWithValue:@"value2" forKey:@"key" hit:self.hit];
[event trigger];
```

Kullandığınız `EDHit` nesnesinin `start` metodu çağırılmış fakat hit henüz serverdan cevap almamışsa eventiniz bu cevap gelene kadar bekletilir, olumlu cevap geldiği anda sunucuya gönderilir. 

Herhangi bir hit ile ilişkili olmayan bir event göndermek isterseniz bu işlemi `EDVisit` classı üzerinden yapabilirsiniz:

```
[[EDVisit currentVisit] triggerEventWithValue:@"value3" forKey:@"key"];
```

Eğer event herhangi bir hit ile ilişkili değilse sunucuya direkt olarak gönderilir. 

###Visitor Bilgileri

8digits API, uygulamanızı kullanan her kullanıcıya tekil bir ID atar. Kullanıcınızın badgeleri ve skoru bu ID üzerinden takip edilir. Uygulamanın herhangi bir yerinden o anki kullanıcıya `[EDVisitor currentVisitor]` ile ulaşabilirsiniz. Visitor bilgileri ancak bir visit başlattığınızda geçerli olur. 

####Badge bilgileri

Uygulamanızın o anki kullanıcısının badge bilgilerine `EDVisitor` nesnesinin `badge` değişkeniyle ulaşabilirsiniz. Bu değişkenin değerinin `nil` olması, badgelerin henüz yüklenmediği anlamına gelir. 8digits API, badgelerin sunucudan asenkronize şekilde çekilmesini de sağlar:

```
self.badges = [[EDVisitor currentVisitor] badges];
	
if (self.badges == nil) {
	[[EDVisitor currentVisitor] loadVisitorBadgesWithCompletionHandler:^(NSArray *badges, NSError *error) {
		if (error != nil) {
			// Badges did not load. Do something with the error.
		}
		
		else {
			self.badges = badges;
		}
	}
}

```
`loadBadgesWithCompletionHandler:` metodunu bir kere çağırmanız sonucu `EDVisitor` nesnesinin `badges` değişkeni güncellenecektir. Sonraki kullanımlarda badgelere direkt olarak `[[EDVisitor currentVisitor] badges]` şeklinde erişebilirsiniz.

### Tum Badge Bilgileri

Hesabızda yer alan tum badge'lere ve bilgilerine ulaşmak için, 

####Skor bilgileri

Uygulamanızın o anki kullanıcısının skor bilgilerine `EDVisitor` nesnesinin `score` değişkeni üzerinden ulaşabilirsiniz. Bu değerin, `integer` tipindeki `EDVisitorScoreNotLoaded` değerine eşit olması, skor bilgisinin henüz sunucudan çekilmediği anlamına gelir. 8digits API, skor bilgisinin sunucudan asenkronize şekilde çekilmesini de sağlar:

```
self.visitorScore = [[EDVisitor currentVisitor] score];

if (visitorScore == EDVisitorScoreNotLoaded) {
	[[EDVisitor currentVisitor] loadScoreWithCompletionHandler:^(NSInteger score, NSString *error) {
		
		 if (error != nil) {
			 // Score failed to load. Do something with the error.
		 }
		 
		 else {
			 visitorScore = score;
		 }
		 
	 }];
```

8digits API bunun yanında, uygulamanızın o anki kullanıcısının skorunu yükseltmenize ya da düşürmenize de olanak sağlar:

```
[[EDVisitor currentVisitor] increaseScoreBy:42 withCompletionHandler:^(NSInteger newScore, NSString *error) {					  
	self.score = newScore; 
}];
```

```
[[EDVisitor currentVisitor] decreaseScoreBy:42 withCompletionHandler:^(NSInteger newScore, NSString *error) {						  
	self.score = newScore; 
}];
```

`EDVisitor` nesnesinin `loadScoreWithCompletionHandler:`, `increaseScoreBy:withCompletionHandler:` ya da `decreaseScoreBy:withCompletionHandler:` metotlarından biri çağırıldığında `score` değişkeni de güncellenir. Bu evreden sonra kullanıcı skoruna `[[EDVisitor currentVisitor] score]` şeklinde ulaşabilirsiniz.