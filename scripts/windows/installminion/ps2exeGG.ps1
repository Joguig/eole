P a r a m ( [ s t r i n g ] $ i n p u t F i l e = $ n u l l ,   [ s t r i n g ] $ o u t p u t F i l e = $ n u l l ,   [ s w i t c h ] $ v e r b o s e ,   [ s w i t c h ]   $ d e b u g ,   [ s w i t c h ] $ r u n t i m e 2 0 ,   [ s w i t c h ] $ r u n t i m e 4 0 ,  
 	 [ s w i t c h ] $ x 8 6 ,   [ s w i t c h ] $ x 6 4 ,   [ i n t ] $ l c i d ,   [ s w i t c h ] $ S t a ,   [ s w i t c h ] $ M t a ,   [ s w i t c h ] $ n o C o n s o l e ,   [ s w i t c h ] $ n e s t e d ,   [ s t r i n g ] $ i c o n F i l e = $ n u l l ,  
 	 [ s t r i n g ] $ t i t l e ,   [ s t r i n g ] $ d e s c r i p t i o n ,   [ s t r i n g ] $ c o m p a n y ,   [ s t r i n g ] $ p r o d u c t ,   [ s t r i n g ] $ c o p y r i g h t ,   [ s t r i n g ] $ t r a d e m a r k ,   [ s t r i n g ] $ v e r s i o n ,  
 	 [ s w i t c h ] $ r e q u i r e A d m i n ,   [ s w i t c h ] $ v i r t u a l i z e ,   [ s w i t c h ] $ c r e d e n t i a l G U I ,   [ s w i t c h ] $ n o C o n f i g f i l e )  
  
 < # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # >  
 < # #                                                                                                                                                         # # >  
 < # #             P S 2 E X E - G U I   v 0 . 5 . 0 . 1 3                                                                                                     # # >  
 < # #             W r i t t e n   b y :   I n g o   K a r s t e i n   ( h t t p : / / b l o g . k a r s t e i n - c o n s u l t i n g . c o m )               # # >  
 < # #             R e w o r k e d   a n d   G U I   s u p p o r t   b y   M a r k u s   S c h o l t e s                                                       # # >  
 < # #                                                                                                                                                         # # >  
 < # #             T h i s   s c r i p t   i s   r e l e a s e d   u n d e r   M i c r o s o f t   P u b l i c   L i c e n c e                                 # # >  
 < # #                     t h a t   c a n   b e   d o w n l o a d e d   h e r e :                                                                             # # >  
 < # #                     h t t p : / / w w w . m i c r o s o f t . c o m / o p e n s o u r c e / l i c e n s e s . m s p x # M s - P L                       # # >  
 < # #                                                                                                                                                         # # >  
 < # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # >  
  
  
 i f   ( ! $ n e s t e d )  
 {  
 	 W r i t e - H o s t   " P S 2 E X E - G U I   v 0 . 5 . 0 . 1 3   b y   I n g o   K a r s t e i n ,   r e w o r k e d   a n d   G U I   s u p p o r t   b y   M a r k u s   S c h o l t e s "  
 }  
 e l s e  
 {  
 	 W r i t e - H o s t   " P o w e r S h e l l   2 . 0   e n v i r o n m e n t   s t a r t e d . . . "  
 }  
 W r i t e - H o s t   " "  
  
 i f   ( $ r u n t i m e 2 0   - a n d   $ r u n t i m e 4 0 )  
 {  
 	 W r i t e - H o s t   " Y o u   c a n n o t   u s e   s w i t c h e s   - r u n t i m e 2 0   a n d   - r u n t i m e 4 0   a t   t h e   s a m e   t i m e ! "  
 	 e x i t   - 1  
 }  
  
 i f   ( $ S t a   - a n d   $ M t a )  
 {  
 	 W r i t e - H o s t   " Y o u   c a n n o t   u s e   s w i t c h e s   - S t a   a n d   - M t a   a t   t h e   s a m e   t i m e ! "  
 	 e x i t   - 1  
 }  
  
 i f   ( [ s t r i n g ] : : I s N u l l O r E m p t y ( $ i n p u t F i l e )   - o r   [ s t r i n g ] : : I s N u l l O r E m p t y ( $ o u t p u t F i l e ) )  
 {  
 	 W r i t e - H o s t   " U s a g e : "  
 	 W r i t e - H o s t   " "  
 	 W r i t e - H o s t   " p o w e r s h e l l . e x e   - c o m m a n d   " " & ' . \ p s 2 e x e . p s 1 '   [ - i n p u t F i l e ]   ' < f i l e _ n a m e > '   [ - o u t p u t F i l e ]   ' < f i l e _ n a m e > '   [ - v e r b o s e ] "  
 	 W r i t e - H o s t   "                               [ - d e b u g ]   [ - r u n t i m e 2 0 | - r u n t i m e 4 0 ]   [ - l c i d   < i d > ]   [ - x 8 6 | - x 6 4 ]   [ - S t a | - M t a ]   [ - n o C o n s o l e ] "  
 	 W r i t e - H o s t   "                               [ - c r e d e n t i a l G U I ]   [ - i c o n F i l e   ' < f i l e _ n a m e > ' ]   [ - t i t l e   ' < t i t l e > ' ]   [ - d e s c r i p t i o n   ' < d e s c r i p t i o n > ' ] "  
 	 W r i t e - H o s t   "                               [ - c o m p a n y   ' < c o m p a n y > ' ]   [ - p r o d u c t   ' < p r o d u c t > ' ]   [ - c o p y r i g h t   ' < c o p y r i g h t > ' ]   [ - t r a d e m a r k   ' < t r a d e m a r k > ' ] "  
 	 W r i t e - H o s t   "                               [ - v e r s i o n   ' < v e r s i o n > ' ]   [ - n o C o n f i g f i l e ]   [ - r e q u i r e A d m i n ]   [ - v i r t u a l i z e ] " " "  
 	 W r i t e - H o s t   " "  
 	 W r i t e - H o s t   "         i n p u t F i l e   =   P o w e r s h e l l   s c r i p t   t h a t   y o u   w a n t   t o   c o n v e r t   t o   E X E "  
 	 W r i t e - H o s t   "       o u t p u t F i l e   =   d e s t i n a t i o n   E X E   f i l e   n a m e "  
 	 W r i t e - H o s t   "             v e r b o s e   =   o u t p u t   v e r b o s e   i n f o r m a t i o n s   -   i f   a n y "  
 	 W r i t e - H o s t   "                 d e b u g   =   g e n e r a t e   d e b u g   i n f o r m a t i o n s   f o r   o u t p u t   f i l e "  
 	 W r i t e - H o s t   "         r u n t i m e 2 0   =   t h i s   s w i t c h   f o r c e s   P S 2 E X E   t o   c r e a t e   a   c o n f i g   f i l e   f o r   t h e   g e n e r a t e d   E X E   t h a t   c o n t a i n s   t h e "  
 	 W r i t e - H o s t   "                                 " " s u p p o r t e d   . N E T   F r a m e w o r k   v e r s i o n s " "   s e t t i n g   f o r   . N E T   F r a m e w o r k   2 . 0 / 3 . x   f o r   P o w e r S h e l l   2 . 0 "  
 	 W r i t e - H o s t   "         r u n t i m e 4 0   =   t h i s   s w i t c h   f o r c e s   P S 2 E X E   t o   c r e a t e   a   c o n f i g   f i l e   f o r   t h e   g e n e r a t e d   E X E   t h a t   c o n t a i n s   t h e "  
 	 W r i t e - H o s t   "                                 " " s u p p o r t e d   . N E T   F r a m e w o r k   v e r s i o n s " "   s e t t i n g   f o r   . N E T   F r a m e w o r k   4 . x   f o r   P o w e r S h e l l   3 . 0   o r   h i g h e r "  
 	 W r i t e - H o s t   "                   l c i d   =   l o c a t i o n   I D   f o r   t h e   c o m p i l e d   E X E .   C u r r e n t   u s e r   c u l t u r e   i f   n o t   s p e c i f i e d "  
 	 W r i t e - H o s t   "                     x 8 6   =   c o m p i l e   f o r   3 2 - b i t   r u n t i m e   o n l y "  
 	 W r i t e - H o s t   "                     x 6 4   =   c o m p i l e   f o r   6 4 - b i t   r u n t i m e   o n l y "  
 	 W r i t e - H o s t   "                     s t a   =   S i n g l e   T h r e a d   A p a r t m e n t   M o d e "  
 	 W r i t e - H o s t   "                     m t a   =   M u l t i   T h r e a d   A p a r t m e n t   M o d e "  
 	 W r i t e - H o s t   "         n o C o n s o l e   =   t h e   r e s u l t i n g   E X E   f i l e   w i l l   b e   a   W i n d o w s   F o r m s   a p p   w i t h o u t   a   c o n s o l e   w i n d o w "  
 	 W r i t e - H o s t   " c r e d e n t i a l G U I   =   u s e   G U I   f o r   p r o m p t i n g   c r e d e n t i a l s   i n   c o n s o l e   m o d e "  
 	 W r i t e - H o s t   "           i c o n F i l e   =   i c o n   f i l e   n a m e   f o r   t h e   c o m p i l e d   E X E "  
 	 W r i t e - H o s t   "                 t i t l e   =   t i t l e   i n f o r m a t i o n   ( d i s p l a y e d   i n   d e t a i l s   t a b   o f   W i n d o w s   E x p l o r e r ' s   p r o p e r t i e s   d i a l o g ) "  
 	 W r i t e - H o s t   "     d e s c r i p t i o n   =   d e s c r i p t i o n   i n f o r m a t i o n   ( n o t   d i s p l a y e d ,   b u t   e m b e d d e d   i n   e x e c u t a b l e ) "  
 	 W r i t e - H o s t   "             c o m p a n y   =   c o m p a n y   i n f o r m a t i o n   ( n o t   d i s p l a y e d ,   b u t   e m b e d d e d   i n   e x e c u t a b l e ) "  
 	 W r i t e - H o s t   "             p r o d u c t   =   p r o d u c t   i n f o r m a t i o n   ( d i s p l a y e d   i n   d e t a i l s   t a b   o f   W i n d o w s   E x p l o r e r ' s   p r o p e r t i e s   d i a l o g ) "  
 	 W r i t e - H o s t   "         c o p y r i g h t   =   c o p y r i g h t   i n f o r m a t i o n   ( d i s p l a y e d   i n   d e t a i l s   t a b   o f   W i n d o w s   E x p l o r e r ' s   p r o p e r t i e s   d i a l o g ) "  
 	 W r i t e - H o s t   "         t r a d e m a r k   =   t r a d e m a r k   i n f o r m a t i o n   ( d i s p l a y e d   i n   d e t a i l s   t a b   o f   W i n d o w s   E x p l o r e r ' s   p r o p e r t i e s   d i a l o g ) "  
 	 W r i t e - H o s t   "             v e r s i o n   =   v e r s i o n   i n f o r m a t i o n   ( d i s p l a y e d   i n   d e t a i l s   t a b   o f   W i n d o w s   E x p l o r e r ' s   p r o p e r t i e s   d i a l o g ) "  
 	 W r i t e - H o s t   "   n o C o n f i g f i l e   =   w r i t e   n o   c o n f i g   f i l e   ( < o u t p u t f i l e > . e x e . c o n f i g ) "  
 	 W r i t e - H o s t   "   r e q u i r e A d m i n   =   i f   U A C   i s   e n a b l e d ,   c o m p i l e d   E X E   r u n   o n l y   i n   e l e v a t e d   c o n t e x t   ( U A C   d i a l o g   a p p e a r s   i f   r e q u i r e d ) "  
 	 W r i t e - H o s t   "       v i r t u a l i z e   =   a p p l i c a t i o n   v i r t u a l i z a t i o n   i s   a c t i v a t e d   ( f o r c i n g   x 8 6   r u n t i m e ) "  
 	 W r i t e - H o s t   " "  
 	 W r i t e - H o s t   " I n p u t   f i l e   o r   o u t p u t   f i l e   n o t   s p e c i f i e d ! "  
 	 e x i t   - 1  
 }  
  
 $ p s v e r s i o n   =   0  
 i f   ( $ P S V e r s i o n T a b l e . P S V e r s i o n . M a j o r   - g e   4 )  
 {  
 	 $ p s v e r s i o n   =   4  
 	 W r i t e - H o s t   " Y o u   a r e   u s i n g   P o w e r S h e l l   4 . 0   o r   a b o v e . "  
 }  
  
 i f   ( $ P S V e r s i o n T a b l e . P S V e r s i o n . M a j o r   - e q   3 )  
 {  
 	 $ p s v e r s i o n   =   3  
 	 W r i t e - H o s t   " Y o u   a r e   u s i n g   P o w e r S h e l l   3 . 0 . "  
 }  
  
 i f   ( $ P S V e r s i o n T a b l e . P S V e r s i o n . M a j o r   - e q   2 )  
 {  
 	 $ p s v e r s i o n   =   2  
 	 W r i t e - H o s t   " Y o u   a r e   u s i n g   P o w e r S h e l l   2 . 0 . "  
 }  
  
 i f   ( $ p s v e r s i o n   - e q   0 )  
 {  
 	 W r i t e - H o s t   " T h e   p o w e r s h e l l   v e r s i o n   i s   u n k n o w n ! "  
 	 e x i t   - 1  
 }  
  
 #   r e t r i e v e   a b s o l u t e   p a t h s   i n d e p e n d e n t   w h e t h e r   p a t h   i s   g i v e n   r e l a t i v e   o d e r   a b s o l u t e  
 $ i n p u t F i l e   =   $ E x e c u t i o n C o n t e x t . S e s s i o n S t a t e . P a t h . G e t U n r e s o l v e d P r o v i d e r P a t h F r o m P S P a t h ( $ i n p u t F i l e )  
 $ o u t p u t F i l e   =   $ E x e c u t i o n C o n t e x t . S e s s i o n S t a t e . P a t h . G e t U n r e s o l v e d P r o v i d e r P a t h F r o m P S P a t h ( $ o u t p u t F i l e )  
  
 i f   ( ! ( T e s t - P a t h   $ i n p u t F i l e   - P a t h T y p e   L e a f ) )  
 {  
 	 W r i t e - H o s t   " I n p u t   f i l e   $ ( $ i n p u t f i l e )   n o t   f o u n d ! "  
 	 e x i t   - 1  
 }  
  
 i f   ( $ i n p u t F i l e   - e q   $ o u t p u t F i l e )  
 {  
 	 W r i t e - H o s t   " I n p u t   f i l e   i s   i d e n t i c a l   t o   o u t p u t   f i l e ! "  
 	 e x i t   - 1  
 }  
  
 i f   ( ! ( [ s t r i n g ] : : I s N u l l O r E m p t y ( $ i c o n F i l e ) ) )  
 {  
 	 #   r e t r i e v e   a b s o l u t e   p a t h   i n d e p e n d e n t   w h e t h e r   p a t h   i s   g i v e n   r e l a t i v e   o d e r   a b s o l u t e  
 	 $ i c o n F i l e   =   $ E x e c u t i o n C o n t e x t . S e s s i o n S t a t e . P a t h . G e t U n r e s o l v e d P r o v i d e r P a t h F r o m P S P a t h ( $ i c o n F i l e )  
  
 	 i f   ( ! ( T e s t - P a t h   $ i c o n F i l e   - P a t h T y p e   L e a f ) )  
 	 {  
 	 	 W r i t e - H o s t   " I c o n   f i l e   $ ( $ i c o n F i l e )   n o t   f o u n d ! "  
 	 	 e x i t   - 1  
 	 }  
 }  
  
 i f   ( $ r e q u i r e A d m i n   - A n d   $ v i r t u a l i z e )  
 {  
 	 W r i t e - H o s t   " - r e q u i r e A d m i n   c a n n o t   b e   c o m b i n e d   w i t h   - v i r t u a l i z e "  
 	 e x i t   - 1  
 }  
  
 i f   ( ! $ r u n t i m e 2 0   - a n d   ! $ r u n t i m e 4 0 )  
 {  
 	 i f   ( $ p s v e r s i o n   - e q   4 )  
 	 {  
 	 	 $ r u n t i m e 4 0   =   $ T R U E  
 	 }  
 	 e l s e i f   ( $ p s v e r s i o n   - e q   3 )  
 	 {  
 	 	 $ r u n t i m e 4 0   =   $ T R U E  
 	 }  
 	 e l s e  
 	 {  
 	 	 $ r u n t i m e 2 0   =   $ T R U E  
 	 }  
 }  
  
 i f   ( $ p s v e r s i o n   - g e   3   - a n d   $ r u n t i m e 2 0 )  
 {  
 	 W r i t e - H o s t   " T o   c r e a t e   a n   E X E   f i l e   f o r   P o w e r S h e l l   2 . 0   o n   P o w e r S h e l l   3 . 0   o r   a b o v e   t h i s   s c r i p t   n o w   l a u n c h e s   P o w e r S h e l l   2 . 0 . . . "  
 	 W r i t e - H o s t   " "  
  
 	 $ a r g u m e n t s   =   " - i n p u t F i l e   ' $ ( $ i n p u t F i l e ) '   - o u t p u t F i l e   ' $ ( $ o u t p u t F i l e ) '   - n e s t e d   "  
  
 	 i f   ( $ v e r b o s e )   {   $ a r g u m e n t s   + =   " - v e r b o s e   " }  
 	 i f   ( $ d e b u g )   {   $ a r g u m e n t s   + =   " - d e b u g   " }  
 	 i f   ( $ r u n t i m e 2 0 )   {   $ a r g u m e n t s   + =   " - r u n t i m e 2 0   " }  
 	 i f   ( $ x 8 6 )   {   $ a r g u m e n t s   + =   " - x 8 6   " }  
 	 i f   ( $ x 6 4 )   {   $ a r g u m e n t s   + =   " - x 6 4   " }  
 	 i f   ( $ l c i d )   {   $ a r g u m e n t s   + =   " - l c i d   $ l c i d   " }  
 	 i f   ( $ S t a )   {   $ a r g u m e n t s   + =   " - S t a   " }  
 	 i f   ( $ M t a )   {   $ a r g u m e n t s   + =   " - M t a   " }  
 	 i f   ( $ n o C o n s o l e )   {   $ a r g u m e n t s   + =   " - n o C o n s o l e   " }  
 	 i f   ( ! ( [ s t r i n g ] : : I s N u l l O r E m p t y ( $ i c o n F i l e ) ) )   {   $ a r g u m e n t s   + =   " - i c o n F i l e   ' $ ( $ i c o n F i l e ) '   " }  
 	 i f   ( ! ( [ s t r i n g ] : : I s N u l l O r E m p t y ( $ t i t l e ) ) )   {   $ a r g u m e n t s   + =   " - t i t l e   ' $ ( $ t i t l e ) '   " }  
 	 i f   ( ! ( [ s t r i n g ] : : I s N u l l O r E m p t y ( $ d e s c r i p t i o n ) ) )   {   $ a r g u m e n t s   + =   " - d e s c r i p t i o n   ' $ ( $ d e s c r i p t i o n ) '   " }  
 	 i f   ( ! ( [ s t r i n g ] : : I s N u l l O r E m p t y ( $ c o m p a n y ) ) )   {   $ a r g u m e n t s   + =   " - c o m p a n y   ' $ ( $ c o m p a n y ) '   " }  
 	 i f   ( ! ( [ s t r i n g ] : : I s N u l l O r E m p t y ( $ p r o d u c t ) ) )   {   $ a r g u m e n t s   + =   " - p r o d u c t   ' $ ( $ p r o d u c t ) '   " }  
 	 i f   ( ! ( [ s t r i n g ] : : I s N u l l O r E m p t y ( $ c o p y r i g h t ) ) )   {   $ a r g u m e n t s   + =   " - c o p y r i g h t   ' $ ( $ c o p y r i g h t ) '   " }  
 	 i f   ( ! ( [ s t r i n g ] : : I s N u l l O r E m p t y ( $ t r a d e m a r k ) ) )   {   $ a r g u m e n t s   + =   " - t r a d e m a r k   ' $ ( $ t r a d e m a r k ) '   " }  
 	 i f   ( ! ( [ s t r i n g ] : : I s N u l l O r E m p t y ( $ v e r s i o n ) ) )   {   $ a r g u m e n t s   + =   " - v e r s i o n   ' $ ( $ v e r s i o n ) '   " }  
 	 i f   ( $ r e q u i r e A d m i n )   {   $ a r g u m e n t s   + =   " - r e q u i r e A d m i n   " }  
 	 i f   ( $ v i r t u a l i z e )   {   $ a r g u m e n t s   + =   " - v i r t u a l i z e   " }  
 	 i f   ( $ c r e d e n t i a l G U I )   {   $ a r g u m e n t s   + =   " - c r e d e n t i a l G U I   " }  
 	 i f   ( $ n o C o n f i g f i l e )   {   $ a r g u m e n t s   + =   " - n o C o n f i g f i l e   " }  
  
 	 i f   ( $ M y I n v o c a t i o n . M y C o m m a n d . C o m m a n d T y p e   - e q   " E x t e r n a l S c r i p t " )  
 	 { 	 #   p s 2 e x e . p s 1   i s   r u n n i n g   ( s c r i p t )  
 	 	 $ j o b S c r i p t   =   @ "  
 . " $ ( $ P S H O M E ) \ p o w e r s h e l l . e x e "   - v e r s i o n   2 . 0   - c o m m a n d   " & ' $ ( $ M y I n v o c a t i o n . M y C o m m a n d . P a t h ) '   $ ( $ a r g u m e n t s ) "  
 " @  
 	 }  
 	 e l s e  
 	 {   #   p s 2 e x e . e x e   i s   r u n n i n g   ( c o m p i l e d   s c r i p t )  
 	 	 W r i t e - H o s t   " T h e   p a r a m e t e r   - r u n t i m e 2 0   i s   n o t   s u p p o r t e d   f o r   c o m p i l e d   p s 2 e x e . p s 1   s c r i p t s . "  
 	 	 W r i t e - H o s t   " C o m p i l e   p s 2 e x e . p s 1   w i t h   p a r a m e t e r   - r u n t i m e 2 0   a n d   c a l l   t h e   g e n e r a t e d   e x e c u t a b l e   ( w i t h o u t   - r u n t i m e 2 0 ) . "  
 	 	 e x i t   - 1  
 	 }  
  
 	 I n v o k e - E x p r e s s i o n   $ j o b S c r i p t  
  
 	 e x i t   0  
 }  
  
 i f   ( $ p s v e r s i o n   - l t   3   - a n d   $ r u n t i m e 4 0 )  
 {  
 	 W r i t e - H o s t   " Y o u   n e e d   t o   r u n   p s 2 e x e   i n   a n   P o w e r s h e l l   3 . 0   o r   h i g h e r   e n v i r o n m e n t   t o   u s e   p a r a m e t e r   - r u n t i m e 4 0 "  
 	 W r i t e - H o s t  
 	 e x i t   - 1  
 }  
  
 i f   ( $ p s v e r s i o n   - l t   3   - a n d   ! $ M t a   - a n d   ! $ S t a )  
 {  
 	 #   S e t   d e f a u l t   a p a r t m e n t   m o d e   f o r   p o w e r s h e l l   v e r s i o n   i f   n o t   s e t   b y   p a r a m e t e r  
 	 $ M t a   =   $ T R U E  
 }  
  
 i f   ( $ p s v e r s i o n   - g e   3   - a n d   ! $ M t a   - a n d   ! $ S t a )  
 {  
 	 #   S e t   d e f a u l t   a p a r t m e n t   m o d e   f o r   p o w e r s h e l l   v e r s i o n   i f   n o t   s e t   b y   p a r a m e t e r  
 	 $ S t a   =   $ T R U E  
 }  
  
 #   e s c a p e   e s c a p e   s e q u e n c e s   i n   v e r s i o n   i n f o  
 $ t i t l e   =   $ t i t l e   - r e p l a c e   " \ \ " ,   " \ \ "  
 $ p r o d u c t   =   $ p r o d u c t   - r e p l a c e   " \ \ " ,   " \ \ "  
 $ c o p y r i g h t   =   $ c o p y r i g h t   - r e p l a c e   " \ \ " ,   " \ \ "  
 $ t r a d e m a r k   =   $ t r a d e m a r k   - r e p l a c e   " \ \ " ,   " \ \ "  
 $ d e s c r i p t i o n   =   $ d e s c r i p t i o n   - r e p l a c e   " \ \ " ,   " \ \ "  
 $ c o m p a n y   =   $ c o m p a n y   - r e p l a c e   " \ \ " ,   " \ \ "  
  
 i f   ( ! [ s t r i n g ] : : I s N u l l O r E m p t y ( $ v e r s i o n ) )  
 {   #   c h e c k   f o r   c o r r e c t   v e r s i o n   n u m b e r   i n f o r m a t i o n  
 	 i f   ( $ v e r s i o n   - n o t m a t c h   " ( ^ \ d + \ . \ d + \ . \ d + \ . \ d + $ ) | ( ^ \ d + \ . \ d + \ . \ d + $ ) | ( ^ \ d + \ . \ d + $ ) | ( ^ \ d + $ ) " )  
 	 {  
 	 	 W r i t e - H o s t   " V e r s i o n   n u m b e r   h a s   t o   b e   s u p p l i e d   i n   t h e   f o r m   n . n . n . n ,   n . n . n ,   n . n   o r   n   ( w i t h   n   a s   n u m b e r ) ! "  
 	 	 e x i t   - 1  
 	 }  
 }  
  
 W r i t e - H o s t   " "  
  
 $ t y p e   =   ( ' S y s t e m . C o l l e c t i o n s . G e n e r i c . D i c t i o n a r y ` 2 ' )   - a s   " T y p e "  
 $ t y p e   =   $ t y p e . M a k e G e n e r i c T y p e (   @ (   ( " S y s t e m . S t r i n g "   - a s   " T y p e " ) ,   ( " s y s t e m . s t r i n g "   - a s   " T y p e " )   )   )  
 $ o   =   [ A c t i v a t o r ] : : C r e a t e I n s t a n c e ( $ t y p e )  
  
 $ c o m p i l e r 2 0   =   $ F A L S E  
 i f   ( $ p s v e r s i o n   - e q   3   - o r   $ p s v e r s i o n   - e q   4 )  
 {  
 	 $ o . A d d ( " C o m p i l e r V e r s i o n " ,   " v 4 . 0 " )  
 }  
 e l s e  
 {  
 	 i f   ( T e s t - P a t h   ( " $ E N V : W I N D I R \ M i c r o s o f t . N E T \ F r a m e w o r k \ v 3 . 5 \ c s c . e x e " ) )  
 	 {    
 	       $ o . A d d ( " C o m p i l e r V e r s i o n " ,   " v 3 . 5 " )    
 	 }  
 	 e l s e  
 	 {  
 	 	 W r i t e - W a r n i n g   " N o   . N e t   3 . 5   c o m p i l e r   f o u n d ,   u s i n g   . N e t   2 . 0   c o m p i l e r . "  
 	 	 W r i t e - W a r n i n g   " T h e r e f o r e   s o m e   m e t h o d s   a r e   n o t   a v a i l a b l e ! "  
 	 	 $ c o m p i l e r 2 0   =   $ T R U E  
 	 	 $ o . A d d ( " C o m p i l e r V e r s i o n " ,   " v 2 . 0 " )  
 	 }  
 }  
  
 $ r e f e r e n c e A s s e m b i e s   =   @ ( " S y s t e m . d l l " )  
 i f   ( ! $ n o C o n s o l e )  
 {  
 	 i f   ( [ S y s t e m . A p p D o m a i n ] : : C u r r e n t D o m a i n . G e t A s s e m b l i e s ( )   |   ?   {   $ _ . M a n i f e s t M o d u l e . N a m e   - i e q   " M i c r o s o f t . P o w e r S h e l l . C o n s o l e H o s t . d l l "   } )  
 	 {  
 	 	 $ r e f e r e n c e A s s e m b i e s   + =   ( [ S y s t e m . A p p D o m a i n ] : : C u r r e n t D o m a i n . G e t A s s e m b l i e s ( )   |   ?   {   $ _ . M a n i f e s t M o d u l e . N a m e   - i e q   " M i c r o s o f t . P o w e r S h e l l . C o n s o l e H o s t . d l l "   }   |   S e l e c t   - F i r s t   1 ) . L o c a t i o n  
 	 }  
 }  
 $ r e f e r e n c e A s s e m b i e s   + =   ( [ S y s t e m . A p p D o m a i n ] : : C u r r e n t D o m a i n . G e t A s s e m b l i e s ( )   |   ?   {   $ _ . M a n i f e s t M o d u l e . N a m e   - i e q   " S y s t e m . M a n a g e m e n t . A u t o m a t i o n . d l l "   }   |   S e l e c t   - F i r s t   1 ) . L o c a t i o n  
  
 i f   ( $ r u n t i m e 4 0 )  
 {  
 	 $ n   =   N e w - O b j e c t   S y s t e m . R e f l e c t i o n . A s s e m b l y N a m e ( " S y s t e m . C o r e ,   V e r s i o n = 4 . 0 . 0 . 0 ,   C u l t u r e = n e u t r a l ,   P u b l i c K e y T o k e n = b 7 7 a 5 c 5 6 1 9 3 4 e 0 8 9 " )  
 	 [ S y s t e m . A p p D o m a i n ] : : C u r r e n t D o m a i n . L o a d ( $ n )   |   O u t - N u l l  
 	 $ r e f e r e n c e A s s e m b i e s   + =   ( [ S y s t e m . A p p D o m a i n ] : : C u r r e n t D o m a i n . G e t A s s e m b l i e s ( )   |   ?   {   $ _ . M a n i f e s t M o d u l e . N a m e   - i e q   " S y s t e m . C o r e . d l l "   }   |   S e l e c t   - F i r s t   1 ) . L o c a t i o n  
 }  
  
 i f   ( $ n o C o n s o l e )  
 {  
 	 $ n   =   N e w - O b j e c t   S y s t e m . R e f l e c t i o n . A s s e m b l y N a m e ( " S y s t e m . W i n d o w s . F o r m s ,   V e r s i o n = 2 . 0 . 0 . 0 ,   C u l t u r e = n e u t r a l ,   P u b l i c K e y T o k e n = b 7 7 a 5 c 5 6 1 9 3 4 e 0 8 9 " )  
 	 i f   ( $ r u n t i m e 4 0 )  
 	 {  
 	 	 $ n   =   N e w - O b j e c t   S y s t e m . R e f l e c t i o n . A s s e m b l y N a m e ( " S y s t e m . W i n d o w s . F o r m s ,   V e r s i o n = 4 . 0 . 0 . 0 ,   C u l t u r e = n e u t r a l ,   P u b l i c K e y T o k e n = b 7 7 a 5 c 5 6 1 9 3 4 e 0 8 9 " )  
 	 }  
 	 [ S y s t e m . A p p D o m a i n ] : : C u r r e n t D o m a i n . L o a d ( $ n )   |   O u t - N u l l  
  
 	 $ n   =   N e w - O b j e c t   S y s t e m . R e f l e c t i o n . A s s e m b l y N a m e ( " S y s t e m . D r a w i n g ,   V e r s i o n = 2 . 0 . 0 . 0 ,   C u l t u r e = n e u t r a l ,   P u b l i c K e y T o k e n = b 0 3 f 5 f 7 f 1 1 d 5 0 a 3 a " )  
 	 i f   ( $ r u n t i m e 4 0 )  
 	 {  
 	 	 $ n   =   N e w - O b j e c t   S y s t e m . R e f l e c t i o n . A s s e m b l y N a m e ( " S y s t e m . D r a w i n g ,   V e r s i o n = 4 . 0 . 0 . 0 ,   C u l t u r e = n e u t r a l ,   P u b l i c K e y T o k e n = b 0 3 f 5 f 7 f 1 1 d 5 0 a 3 a " )  
 	 }  
 	 [ S y s t e m . A p p D o m a i n ] : : C u r r e n t D o m a i n . L o a d ( $ n )   |   O u t - N u l l  
  
 	 $ r e f e r e n c e A s s e m b i e s   + =   ( [ S y s t e m . A p p D o m a i n ] : : C u r r e n t D o m a i n . G e t A s s e m b l i e s ( )   |   ?   {   $ _ . M a n i f e s t M o d u l e . N a m e   - i e q   " S y s t e m . W i n d o w s . F o r m s . d l l "   }   |   S e l e c t   - F i r s t   1 ) . L o c a t i o n  
 	 $ r e f e r e n c e A s s e m b i e s   + =   ( [ S y s t e m . A p p D o m a i n ] : : C u r r e n t D o m a i n . G e t A s s e m b l i e s ( )   |   ?   {   $ _ . M a n i f e s t M o d u l e . N a m e   - i e q   " S y s t e m . D r a w i n g . d l l "   }   |   S e l e c t   - F i r s t   1 ) . L o c a t i o n  
 }  
  
 $ p l a t f o r m   =   " a n y c p u "  
 i f   ( $ x 6 4   - a n d   ! $ x 8 6 )   {   $ p l a t f o r m   =   " x 6 4 "   }   e l s e   {   i f   ( $ x 8 6   - a n d   ! $ x 6 4 )   {   $ p l a t f o r m   =   " x 8 6 "   } }  
  
 $ c o p   =   ( N e w - O b j e c t   M i c r o s o f t . C S h a r p . C S h a r p C o d e P r o v i d e r ( $ o ) )  
 $ c p   =   N e w - O b j e c t   S y s t e m . C o d e D o m . C o m p i l e r . C o m p i l e r P a r a m e t e r s ( $ r e f e r e n c e A s s e m b i e s ,   $ o u t p u t F i l e )  
 $ c p . G e n e r a t e I n M e m o r y   =   $ F A L S E  
 $ c p . G e n e r a t e E x e c u t a b l e   =   $ T R U E  
  
 $ i c o n F i l e P a r a m   =   " "  
 i f   ( ! ( [ s t r i n g ] : : I s N u l l O r E m p t y ( $ i c o n F i l e ) ) )  
 {  
 	 $ i c o n F i l e P a r a m   =   " ` " / w i n 3 2 i c o n : $ ( $ i c o n F i l e ) ` " "  
 }  
  
 $ r e q A d m P a r a m   =   " "  
 i f   ( $ r e q u i r e A d m i n )  
 {  
 	 $ w i n 3 2 m a n i f e s t   =   " < ? x m l   v e r s i o n = " " 1 . 0 " "   e n c o d i n g = " " U T F - 8 " "   s t a n d a l o n e = " " y e s " " ? > ` r ` n < a s s e m b l y   x m l n s = " " u r n : s c h e m a s - m i c r o s o f t - c o m : a s m . v 1 " "   m a n i f e s t V e r s i o n = " " 1 . 0 " " > ` r ` n < t r u s t I n f o   x m l n s = " " u r n : s c h e m a s - m i c r o s o f t - c o m : a s m . v 2 " " > ` r ` n < s e c u r i t y > ` r ` n < r e q u e s t e d P r i v i l e g e s   x m l n s = " " u r n : s c h e m a s - m i c r o s o f t - c o m : a s m . v 3 " " > ` r ` n < r e q u e s t e d E x e c u t i o n L e v e l   l e v e l = " " r e q u i r e A d m i n i s t r a t o r " "   u i A c c e s s = " " f a l s e " " / > ` r ` n < / r e q u e s t e d P r i v i l e g e s > ` r ` n < / s e c u r i t y > ` r ` n < / t r u s t I n f o > ` r ` n < / a s s e m b l y > "  
 	 $ w i n 3 2 m a n i f e s t   |   S e t - C o n t e n t   ( $ o u t p u t F i l e + " . w i n 3 2 m a n i f e s t " )   - E n c o d i n g   U T F 8  
  
 	 $ r e q A d m P a r a m   =   " ` " / w i n 3 2 m a n i f e s t : $ ( $ o u t p u t F i l e + " . w i n 3 2 m a n i f e s t " ) ` " "  
 }  
  
 i f   ( ! $ v i r t u a l i z e )  
 {    
       $ c p . C o m p i l e r O p t i o n s   =   " / p l a t f o r m : $ ( $ p l a t f o r m )   / t a r g e t : $ (   i f   ( $ n o C o n s o l e ) { ' w i n e x e ' } e l s e { ' e x e ' } )   $ ( $ i c o n F i l e P a r a m )   $ ( $ r e q A d m P a r a m ) "   }  
 e l s e  
 {      
       W r i t e - H o s t   " A p p l i c a t i o n   v i r t u a l i z a t i o n   i s   a c t i v a t e d ,   f o r c i n g   x 8 6   p l a t f o m . "  
       $ c p . C o m p i l e r O p t i o n s   =   " / p l a t f o r m : x 8 6   / t a r g e t : $ (   i f   ( $ n o C o n s o l e )   {   ' w i n e x e '   }   e l s e   {   ' e x e '   }   )   / n o w i n 3 2 m a n i f e s t   $ ( $ i c o n F i l e P a r a m ) "  
 }  
  
 $ c p . I n c l u d e D e b u g I n f o r m a t i o n   =   $ d e b u g  
  
 i f   ( $ d e b u g )  
 {  
 	 $ c p . T e m p F i l e s . K e e p F i l e s   =   $ T R U E  
 }  
  
 W r i t e - H o s t   " R e a d i n g   i n p u t   f i l e   "   - N o N e w l i n e  
 W r i t e - H o s t   $ i n p u t F i l e  
 W r i t e - H o s t   " "  
 $ c o n t e n t   =   G e t - C o n t e n t   - L i t e r a l P a t h   ( $ i n p u t F i l e )   - E n c o d i n g   U T F 8   - E r r o r A c t i o n   S i l e n t l y C o n t i n u e  
 i f   ( $ c o n t e n t   - e q   $ n u l l )  
 {  
 	 W r i t e - H o s t   " N o   d a t a   f o u n d .   M a y   b e   r e a d   e r r o r   o r   f i l e   p r o t e c t e d . "  
 	 e x i t   - 2  
 }  
 $ s c r i p t I n p   =   [ s t r i n g ] : : J o i n ( " ` r ` n " ,   $ c o n t e n t )  
 $ s c r i p t   =   [ S y s t e m . C o n v e r t ] : : T o B a s e 6 4 S t r i n g ( ( [ S y s t e m . T e x t . E n c o d i n g ] : : U T F 8 . G e t B y t e s ( $ s c r i p t I n p ) ) )  
  
 # r e g i o n   p r o g r a m   f r a m e  
 $ c u l t u r e   =   " "  
  
 i f   ( $ l c i d )  
 {  
 	 $ c u l t u r e   =   @ "  
 	 S y s t e m . T h r e a d i n g . T h r e a d . C u r r e n t T h r e a d . C u r r e n t C u l t u r e   =   S y s t e m . G l o b a l i z a t i o n . C u l t u r e I n f o . G e t C u l t u r e I n f o ( $ l c i d ) ;  
 	 S y s t e m . T h r e a d i n g . T h r e a d . C u r r e n t T h r e a d . C u r r e n t U I C u l t u r e   =   S y s t e m . G l o b a l i z a t i o n . C u l t u r e I n f o . G e t C u l t u r e I n f o ( $ l c i d ) ;  
 " @  
 }  
  
 $ p r o g r a m F r a m e   =   @ "  
 / /   S i m p l e   P o w e r S h e l l   h o s t   c r e a t e d   b y   I n g o   K a r s t e i n   ( h t t p : / / b l o g . k a r s t e i n - c o n s u l t i n g . c o m )   f o r   P S 2 E X E  
 / /   R e w o r k e d   a n d   G U I   s u p p o r t   b y   M a r k u s   S c h o l t e s  
  
 u s i n g   S y s t e m ;  
 u s i n g   S y s t e m . C o l l e c t i o n s . G e n e r i c ;  
 u s i n g   S y s t e m . T e x t ;  
 u s i n g   S y s t e m . M a n a g e m e n t . A u t o m a t i o n ;  
 u s i n g   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . R u n s p a c e s ;  
 u s i n g   P o w e r S h e l l   =   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . P o w e r S h e l l ;  
 u s i n g   S y s t e m . G l o b a l i z a t i o n ;  
 u s i n g   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t ;  
 u s i n g   S y s t e m . S e c u r i t y ;  
 u s i n g   S y s t e m . R e f l e c t i o n ;  
 u s i n g   S y s t e m . R u n t i m e . I n t e r o p S e r v i c e s ;  
 $ ( i f   ( $ n o C o n s o l e )   { @ "  
 u s i n g   S y s t e m . W i n d o w s . F o r m s ;  
 u s i n g   S y s t e m . D r a w i n g ;  
 " @   } )  
  
 [ a s s e m b l y : A s s e m b l y T i t l e ( " $ t i t l e " ) ]  
 [ a s s e m b l y : A s s e m b l y P r o d u c t ( " $ p r o d u c t " ) ]  
 [ a s s e m b l y : A s s e m b l y C o p y r i g h t ( " $ c o p y r i g h t " ) ]  
 [ a s s e m b l y : A s s e m b l y T r a d e m a r k ( " $ t r a d e m a r k " ) ]  
 $ ( i f   ( ! [ s t r i n g ] : : I s N u l l O r E m p t y ( $ v e r s i o n ) )   { @ "  
 [ a s s e m b l y : A s s e m b l y V e r s i o n ( " $ v e r s i o n " ) ]  
 [ a s s e m b l y : A s s e m b l y F i l e V e r s i o n ( " $ v e r s i o n " ) ]  
 " @   } )  
 / /   n o t   d i s p l a y e d   i n   d e t a i l s   t a b   o f   p r o p e r t i e s   d i a l o g ,   b u t   e m b e d d e d   t o   f i l e  
 [ a s s e m b l y : A s s e m b l y D e s c r i p t i o n ( " $ d e s c r i p t i o n " ) ]  
 [ a s s e m b l y : A s s e m b l y C o m p a n y ( " $ c o m p a n y " ) ]  
  
 n a m e s p a c e   i k . P o w e r S h e l l  
 {  
 $ ( i f   ( $ n o C o n s o l e   - o r   $ c r e d e n t i a l G U I )   { @ "  
 	 i n t e r n a l   c l a s s   C r e d e n t i a l F o r m  
 	 {  
 	 	 [ S t r u c t L a y o u t ( L a y o u t K i n d . S e q u e n t i a l ,   C h a r S e t   =   C h a r S e t . U n i c o d e ) ]  
 	 	 p r i v a t e   s t r u c t   C R E D U I _ I N F O  
 	 	 {  
 	 	 	 p u b l i c   i n t   c b S i z e ;  
 	 	 	 p u b l i c   I n t P t r   h w n d P a r e n t ;  
 	 	 	 p u b l i c   s t r i n g   p s z M e s s a g e T e x t ;  
 	 	 	 p u b l i c   s t r i n g   p s z C a p t i o n T e x t ;  
 	 	 	 p u b l i c   I n t P t r   h b m B a n n e r ;  
 	 	 }  
  
 	 	 [ F l a g s ]  
 	 	 e n u m   C R E D U I _ F L A G S  
 	 	 {  
 	 	 	 I N C O R R E C T _ P A S S W O R D   =   0 x 1 ,  
 	 	 	 D O _ N O T _ P E R S I S T   =   0 x 2 ,  
 	 	 	 R E Q U E S T _ A D M I N I S T R A T O R   =   0 x 4 ,  
 	 	 	 E X C L U D E _ C E R T I F I C A T E S   =   0 x 8 ,  
 	 	 	 R E Q U I R E _ C E R T I F I C A T E   =   0 x 1 0 ,  
 	 	 	 S H O W _ S A V E _ C H E C K _ B O X   =   0 x 4 0 ,  
 	 	 	 A L W A Y S _ S H O W _ U I   =   0 x 8 0 ,  
 	 	 	 R E Q U I R E _ S M A R T C A R D   =   0 x 1 0 0 ,  
 	 	 	 P A S S W O R D _ O N L Y _ O K   =   0 x 2 0 0 ,  
 	 	 	 V A L I D A T E _ U S E R N A M E   =   0 x 4 0 0 ,  
 	 	 	 C O M P L E T E _ U S E R N A M E   =   0 x 8 0 0 ,  
 	 	 	 P E R S I S T   =   0 x 1 0 0 0 ,  
 	 	 	 S E R V E R _ C R E D E N T I A L   =   0 x 4 0 0 0 ,  
 	 	 	 E X P E C T _ C O N F I R M A T I O N   =   0 x 2 0 0 0 0 ,  
 	 	 	 G E N E R I C _ C R E D E N T I A L S   =   0 x 4 0 0 0 0 ,  
 	 	 	 U S E R N A M E _ T A R G E T _ C R E D E N T I A L S   =   0 x 8 0 0 0 0 ,  
 	 	 	 K E E P _ U S E R N A M E   =   0 x 1 0 0 0 0 0 ,  
 	 	 }  
  
 	 	 p u b l i c   e n u m   C r e d U I R e t u r n C o d e s  
 	 	 {  
 	 	 	 N O _ E R R O R   =   0 ,  
 	 	 	 E R R O R _ C A N C E L L E D   =   1 2 2 3 ,  
 	 	 	 E R R O R _ N O _ S U C H _ L O G O N _ S E S S I O N   =   1 3 1 2 ,  
 	 	 	 E R R O R _ N O T _ F O U N D   =   1 1 6 8 ,  
 	 	 	 E R R O R _ I N V A L I D _ A C C O U N T _ N A M E   =   1 3 1 5 ,  
 	 	 	 E R R O R _ I N S U F F I C I E N T _ B U F F E R   =   1 2 2 ,  
 	 	 	 E R R O R _ I N V A L I D _ P A R A M E T E R   =   8 7 ,  
 	 	 	 E R R O R _ I N V A L I D _ F L A G S   =   1 0 0 4 ,  
 	 	 }  
  
 	 	 [ D l l I m p o r t ( " c r e d u i " ,   C h a r S e t   =   C h a r S e t . U n i c o d e ) ]  
 	 	 p r i v a t e   s t a t i c   e x t e r n   C r e d U I R e t u r n C o d e s   C r e d U I P r o m p t F o r C r e d e n t i a l s ( r e f   C R E D U I _ I N F O   c r e d i t U R ,  
 	 	 	 s t r i n g   t a r g e t N a m e ,  
 	 	 	 I n t P t r   r e s e r v e d 1 ,  
 	 	 	 i n t   i E r r o r ,  
 	 	 	 S t r i n g B u i l d e r   u s e r N a m e ,  
 	 	 	 i n t   m a x U s e r N a m e ,  
 	 	 	 S t r i n g B u i l d e r   p a s s w o r d ,  
 	 	 	 i n t   m a x P a s s w o r d ,  
 	 	 	 [ M a r s h a l A s ( U n m a n a g e d T y p e . B o o l ) ]   r e f   b o o l   p f S a v e ,  
 	 	 	 C R E D U I _ F L A G S   f l a g s ) ;  
  
 	 	 p u b l i c   c l a s s   U s e r P w d  
 	 	 {  
 	 	 	 p u b l i c   s t r i n g   U s e r   =   s t r i n g . E m p t y ;  
 	 	 	 p u b l i c   s t r i n g   P a s s w o r d   =   s t r i n g . E m p t y ;  
 	 	 	 p u b l i c   s t r i n g   D o m a i n   =   s t r i n g . E m p t y ;  
 	 	 }  
  
 	 	 i n t e r n a l   s t a t i c   U s e r P w d   P r o m p t F o r P a s s w o r d ( s t r i n g   c a p t i o n ,   s t r i n g   m e s s a g e ,   s t r i n g   t a r g e t ,   s t r i n g   u s e r ,   P S C r e d e n t i a l T y p e s   c r e d T y p e s ,   P S C r e d e n t i a l U I O p t i o n s   o p t i o n s )  
 	 	 {  
 	 	 	 / /   F l a g s   u n d   V a r i a b l e n   i n i t i a l i s i e r e n  
 	 	 	 S t r i n g B u i l d e r   u s e r P a s s w o r d   =   n e w   S t r i n g B u i l d e r ( ) ,   u s e r I D   =   n e w   S t r i n g B u i l d e r ( u s e r ,   1 2 8 ) ;  
 	 	 	 C R E D U I _ I N F O   c r e d U I   =   n e w   C R E D U I _ I N F O ( ) ;  
 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( m e s s a g e ) )   c r e d U I . p s z M e s s a g e T e x t   =   m e s s a g e ;  
 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( c a p t i o n ) )   c r e d U I . p s z C a p t i o n T e x t   =   c a p t i o n ;  
 	 	 	 c r e d U I . c b S i z e   =   M a r s h a l . S i z e O f ( c r e d U I ) ;  
 	 	 	 b o o l   s a v e   =   f a l s e ;  
  
 	 	 	 C R E D U I _ F L A G S   f l a g s   =   C R E D U I _ F L A G S . D O _ N O T _ P E R S I S T ;  
 	 	 	 i f   ( ( c r e d T y p e s   &   P S C r e d e n t i a l T y p e s . G e n e r i c )   = =   P S C r e d e n t i a l T y p e s . G e n e r i c )  
 	 	 	 {  
 	 	 	 	 f l a g s   | =   C R E D U I _ F L A G S . G E N E R I C _ C R E D E N T I A L S ;  
 	 	 	 	 i f   ( ( o p t i o n s   &   P S C r e d e n t i a l U I O p t i o n s . A l w a y s P r o m p t )   = =   P S C r e d e n t i a l U I O p t i o n s . A l w a y s P r o m p t )  
 	 	 	 	 {  
 	 	 	 	 	 f l a g s   | =   C R E D U I _ F L A G S . A L W A Y S _ S H O W _ U I ;  
 	 	 	 	 }  
 	 	 	 }  
  
 	 	 	 / /   d e n   B e n u t z e r   n a c h   K e n n w o r t   f r a g e n ,   g r a f i s c h e r   P r o m p t  
 	 	 	 C r e d U I R e t u r n C o d e s   r e t u r n C o d e   =   C r e d U I P r o m p t F o r C r e d e n t i a l s ( r e f   c r e d U I ,   t a r g e t ,   I n t P t r . Z e r o ,   0 ,   u s e r I D ,   1 2 8 ,   u s e r P a s s w o r d ,   1 2 8 ,   r e f   s a v e ,   f l a g s ) ;  
  
 	 	 	 i f   ( r e t u r n C o d e   = =   C r e d U I R e t u r n C o d e s . N O _ E R R O R )  
 	 	 	 {  
 	 	 	 	 U s e r P w d   r e t   =   n e w   U s e r P w d ( ) ;  
 	 	 	 	 r e t . U s e r   =   u s e r I D . T o S t r i n g ( ) ;  
 	 	 	 	 r e t . P a s s w o r d   =   u s e r P a s s w o r d . T o S t r i n g ( ) ;  
 	 	 	 	 r e t . D o m a i n   =   " " ;  
 	 	 	 	 r e t u r n   r e t ;  
 	 	 	 }  
  
 	 	 	 r e t u r n   n u l l ;  
 	 	 }  
 	 }  
 " @   } )  
  
 	 i n t e r n a l   c l a s s   P S 2 E X E H o s t R a w U I   :   P S H o s t R a w U s e r I n t e r f a c e  
 	 {  
 $ ( i f   ( $ n o C o n s o l e ) {   @ "  
 	 	 / /   S p e i c h e r   f � r   K o n s o l e n f a r b e n   b e i   G U I - O u t p u t   w e r d e n   g e l e s e n   u n d   g e s e t z t ,   a b e r   i m   M o m e n t   n i c h t   g e n u t z t   ( f o r   f u t u r e   u s e )  
 	 	 p r i v a t e   C o n s o l e C o l o r   n c B a c k g r o u n d C o l o r   =   C o n s o l e C o l o r . W h i t e ;  
 	 	 p r i v a t e   C o n s o l e C o l o r   n c F o r e g r o u n d C o l o r   =   C o n s o l e C o l o r . B l a c k ;  
 " @   }   e l s e   { @ "  
 	 	 c o n s t   i n t   S T D _ O U T P U T _ H A N D L E   =   - 1 1 ;  
  
 	 	 / / C H A R _ I N F O   s t r u c t ,   w h i c h   w a s   a   u n i o n   i n   t h e   o l d   d a y s  
 	 	 / /   s o   w e   w a n t   t o   u s e   L a y o u t K i n d . E x p l i c i t   t o   m i m i c   i t   a s   c l o s e l y  
 	 	 / /   a s   w e   c a n  
 	 	 [ S t r u c t L a y o u t ( L a y o u t K i n d . E x p l i c i t ) ]  
 	 	 p u b l i c   s t r u c t   C H A R _ I N F O  
 	 	 {  
 	 	 	 [ F i e l d O f f s e t ( 0 ) ]  
 	 	 	 i n t e r n a l   c h a r   U n i c o d e C h a r ;  
 	 	 	 [ F i e l d O f f s e t ( 0 ) ]  
 	 	 	 i n t e r n a l   c h a r   A s c i i C h a r ;  
 	 	 	 [ F i e l d O f f s e t ( 2 ) ]   / / 2   b y t e s   s e e m s   t o   w o r k   p r o p e r l y  
 	 	 	 i n t e r n a l   U I n t 1 6   A t t r i b u t e s ;  
 	 	 }  
  
 	 	 / / C O O R D   s t r u c t  
 	 	 [ S t r u c t L a y o u t ( L a y o u t K i n d . S e q u e n t i a l ) ]  
 	 	 p u b l i c   s t r u c t   C O O R D  
 	 	 {  
 	 	 	 p u b l i c   s h o r t   X ;  
 	 	 	 p u b l i c   s h o r t   Y ;  
 	 	 }  
  
 	 	 / / S M A L L _ R E C T   s t r u c t  
 	 	 [ S t r u c t L a y o u t ( L a y o u t K i n d . S e q u e n t i a l ) ]  
 	 	 p u b l i c   s t r u c t   S M A L L _ R E C T  
 	 	 {  
 	 	 	 p u b l i c   s h o r t   L e f t ;  
 	 	 	 p u b l i c   s h o r t   T o p ;  
 	 	 	 p u b l i c   s h o r t   R i g h t ;  
 	 	 	 p u b l i c   s h o r t   B o t t o m ;  
 	 	 }  
  
 	 	 / *   R e a d s   c h a r a c t e r   a n d   c o l o r   a t t r i b u t e   d a t a   f r o m   a   r e c t a n g u l a r   b l o c k   o f   c h a r a c t e r   c e l l s   i n   a   c o n s o l e   s c r e e n   b u f f e r ,  
 	 	 	   a n d   t h e   f u n c t i o n   w r i t e s   t h e   d a t a   t o   a   r e c t a n g u l a r   b l o c k   a t   a   s p e c i f i e d   l o c a t i o n   i n   t h e   d e s t i n a t i o n   b u f f e r .   * /  
 	 	 [ D l l I m p o r t ( " k e r n e l 3 2 . d l l " ,   E n t r y P o i n t   =   " R e a d C o n s o l e O u t p u t W " ,   C h a r S e t   =   C h a r S e t . U n i c o d e ,   S e t L a s t E r r o r   =   t r u e ) ]  
 	 	 i n t e r n a l   s t a t i c   e x t e r n   b o o l   R e a d C o n s o l e O u t p u t (  
 	 	 	 I n t P t r   h C o n s o l e O u t p u t ,  
 	 	 	 / *   T h i s   p o i n t e r   i s   t r e a t e d   a s   t h e   o r i g i n   o f   a   t w o - d i m e n s i o n a l   a r r a y   o f   C H A R _ I N F O   s t r u c t u r e s  
 	 	 	 w h o s e   s i z e   i s   s p e c i f i e d   b y   t h e   d w B u f f e r S i z e   p a r a m e t e r . * /  
 	 	 	 [ M a r s h a l A s ( U n m a n a g e d T y p e . L P A r r a y ) ,   O u t ]   C H A R _ I N F O [ , ]   l p B u f f e r ,  
 	 	 	 C O O R D   d w B u f f e r S i z e ,  
 	 	 	 C O O R D   d w B u f f e r C o o r d ,  
 	 	 	 r e f   S M A L L _ R E C T   l p R e a d R e g i o n ) ;  
  
 	 	 / *   W r i t e s   c h a r a c t e r   a n d   c o l o r   a t t r i b u t e   d a t a   t o   a   s p e c i f i e d   r e c t a n g u l a r   b l o c k   o f   c h a r a c t e r   c e l l s   i n   a   c o n s o l e   s c r e e n   b u f f e r .  
 	 	 	 T h e   d a t a   t o   b e   w r i t t e n   i s   t a k e n   f r o m   a   c o r r e s p o n d i n g l y   s i z e d   r e c t a n g u l a r   b l o c k   a t   a   s p e c i f i e d   l o c a t i o n   i n   t h e   s o u r c e   b u f f e r   * /  
 	 	 [ D l l I m p o r t ( " k e r n e l 3 2 . d l l " ,   E n t r y P o i n t   =   " W r i t e C o n s o l e O u t p u t W " ,   C h a r S e t   =   C h a r S e t . U n i c o d e ,   S e t L a s t E r r o r   =   t r u e ) ]  
 	 	 i n t e r n a l   s t a t i c   e x t e r n   b o o l   W r i t e C o n s o l e O u t p u t (  
 	 	 	 I n t P t r   h C o n s o l e O u t p u t ,  
 	 	 	 / *   T h i s   p o i n t e r   i s   t r e a t e d   a s   t h e   o r i g i n   o f   a   t w o - d i m e n s i o n a l   a r r a y   o f   C H A R _ I N F O   s t r u c t u r e s  
 	 	 	 w h o s e   s i z e   i s   s p e c i f i e d   b y   t h e   d w B u f f e r S i z e   p a r a m e t e r . * /  
 	 	 	 [ M a r s h a l A s ( U n m a n a g e d T y p e . L P A r r a y ) ,   I n ]   C H A R _ I N F O [ , ]   l p B u f f e r ,  
 	 	 	 C O O R D   d w B u f f e r S i z e ,  
 	 	 	 C O O R D   d w B u f f e r C o o r d ,  
 	 	 	 r e f   S M A L L _ R E C T   l p W r i t e R e g i o n ) ;  
  
 	 	 / *   M o v e s   a   b l o c k   o f   d a t a   i n   a   s c r e e n   b u f f e r .   T h e   e f f e c t s   o f   t h e   m o v e   c a n   b e   l i m i t e d   b y   s p e c i f y i n g   a   c l i p p i n g   r e c t a n g l e ,   s o  
 	 	 	 t h e   c o n t e n t s   o f   t h e   c o n s o l e   s c r e e n   b u f f e r   o u t s i d e   t h e   c l i p p i n g   r e c t a n g l e   a r e   u n c h a n g e d .   * /  
 	 	 [ D l l I m p o r t ( " k e r n e l 3 2 . d l l " ,   S e t L a s t E r r o r   =   t r u e ) ]  
 	 	 s t a t i c   e x t e r n   b o o l   S c r o l l C o n s o l e S c r e e n B u f f e r (  
 	 	 	 I n t P t r   h C o n s o l e O u t p u t ,  
 	 	 	 [ I n ]   r e f   S M A L L _ R E C T   l p S c r o l l R e c t a n g l e ,  
 	 	 	 [ I n ]   r e f   S M A L L _ R E C T   l p C l i p R e c t a n g l e ,  
 	 	 	 C O O R D   d w D e s t i n a t i o n O r i g i n ,  
 	 	 	 [ I n ]   r e f   C H A R _ I N F O   l p F i l l ) ;  
  
 	 	 [ D l l I m p o r t ( " k e r n e l 3 2 . d l l " ,   S e t L a s t E r r o r   =   t r u e ) ]  
 	 	 	 s t a t i c   e x t e r n   I n t P t r   G e t S t d H a n d l e ( i n t   n S t d H a n d l e ) ;  
 " @   } )  
  
 	 	 p u b l i c   o v e r r i d e   C o n s o l e C o l o r   B a c k g r o u n d C o l o r  
 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e ) {   @ "  
 	 	 	 g e t  
 	 	 	 {  
 	 	 	 	 r e t u r n   C o n s o l e . B a c k g r o u n d C o l o r ;  
 	 	 	 }  
 	 	 	 s e t  
 	 	 	 {  
 	 	 	 	 C o n s o l e . B a c k g r o u n d C o l o r   =   v a l u e ;  
 	 	 	 }  
 " @   }   e l s e   { @ "  
 	 	 	 g e t  
 	 	 	 {  
 	 	 	 	 r e t u r n   n c B a c k g r o u n d C o l o r ;  
 	 	 	 }  
 	 	 	 s e t  
 	 	 	 {  
 	 	 	 	 n c B a c k g r o u n d C o l o r   =   v a l u e ;  
 	 	 	 }  
 " @   } )  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . S i z e   B u f f e r S i z e  
 	 	 {  
 	 	 	 g e t  
 	 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e ) {   @ "  
 	 	 	 	 i f   ( C o n s o l e I n f o . I s O u t p u t R e d i r e c t e d ( ) )  
 	 	 	 	 	 / /   r e t u r n   d e f a u l t   v a l u e   f o r   r e d i r e c t i o n .   I f   n o   v a l i d   v a l u e   i s   r e t u r n e d   W r i t e L i n e   w i l l   n o t   b e   c a l l e d  
 	 	 	 	 	 r e t u r n   n e w   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . S i z e ( 1 2 0 ,   5 0 ) ;  
 	 	 	 	 e l s e  
 	 	 	 	 	 r e t u r n   n e w   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . S i z e ( C o n s o l e . B u f f e r W i d t h ,   C o n s o l e . B u f f e r H e i g h t ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 	 	 / /   r e t u r n   d e f a u l t   v a l u e   f o r   W i n f o r m s .   I f   n o   v a l i d   v a l u e   i s   r e t u r n e d   W r i t e L i n e   w i l l   n o t   b e   c a l l e d  
 	 	 	 	 r e t u r n   n e w   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . S i z e ( 1 2 0 ,   5 0 ) ;  
 " @   } )  
 	 	 	 }  
 	 	 	 s e t  
 	 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e ) {   @ "  
 	 	 	 	 C o n s o l e . B u f f e r W i d t h   =   v a l u e . W i d t h ;  
 	 	 	 	 C o n s o l e . B u f f e r H e i g h t   =   v a l u e . H e i g h t ;  
 " @   } )  
 	 	 	 }  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   C o o r d i n a t e s   C u r s o r P o s i t i o n  
 	 	 {  
 	 	 	 g e t  
 	 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e ) {   @ "  
 	 	 	 	 r e t u r n   n e w   C o o r d i n a t e s ( C o n s o l e . C u r s o r L e f t ,   C o n s o l e . C u r s o r T o p ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 	 / /   D u m m y w e r t   f � r   W i n f o r m s   z u r � c k g e b e n .  
 	 	 	 	 r e t u r n   n e w   C o o r d i n a t e s ( 0 ,   0 ) ;  
 " @   } )  
 	 	 	 }  
 	 	 	 s e t  
 	 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e ) {   @ "  
 	 	 	 	 C o n s o l e . C u r s o r T o p   =   v a l u e . Y ;  
 	 	 	 	 C o n s o l e . C u r s o r L e f t   =   v a l u e . X ;  
 " @   } )  
 	 	 	 }  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   i n t   C u r s o r S i z e  
 	 	 {  
 	 	 	 g e t  
 	 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e ) {   @ "  
 	 	 	 	 r e t u r n   C o n s o l e . C u r s o r S i z e ;  
 " @   }   e l s e   { @ "  
 	 	 	 	 / /   D u m m y w e r t   f � r   W i n f o r m s   z u r � c k g e b e n .  
 	 	 	 	 r e t u r n   2 5 ;  
 " @   } )  
 	 	 	 }  
 	 	 	 s e t  
 	 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e ) {   @ "  
 	 	 	 	 C o n s o l e . C u r s o r S i z e   =   v a l u e ;  
 " @   } )  
 	 	 	 }  
 	 	 }  
  
 $ ( i f   ( $ n o C o n s o l e ) {   @ "  
 	 	 p r i v a t e   F o r m   I n v i s i b l e F o r m   =   n u l l ;  
 " @   } )  
  
 	 	 p u b l i c   o v e r r i d e   v o i d   F l u s h I n p u t B u f f e r ( )  
 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e ) {   @ "  
 	 	 	 i f   ( ! C o n s o l e I n f o . I s I n p u t R e d i r e c t e d ( ) )  
 	 	 	 { 	 w h i l e   ( C o n s o l e . K e y A v a i l a b l e )  
         	 	 	 C o n s o l e . R e a d K e y ( t r u e ) ;  
         	 }  
 " @   }   e l s e   { @ "  
 	 	 	 i f   ( I n v i s i b l e F o r m   ! =   n u l l )  
 	 	 	 {  
 	 	 	 	 I n v i s i b l e F o r m . C l o s e ( ) ;  
 	 	 	 	 I n v i s i b l e F o r m   =   n u l l ;  
 	 	 	 }  
 	 	 	 e l s e  
 	 	 	 {  
 	 	 	 	 I n v i s i b l e F o r m   =   n e w   F o r m ( ) ;  
 	 	 	 	 I n v i s i b l e F o r m . O p a c i t y   =   0 ;  
 	 	 	 	 I n v i s i b l e F o r m . S h o w I n T a s k b a r   =   f a l s e ;  
 	 	 	 	 I n v i s i b l e F o r m . V i s i b l e   =   t r u e ;  
 	 	 	 }  
 " @   } )  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   C o n s o l e C o l o r   F o r e g r o u n d C o l o r  
 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e ) {   @ "  
 	 	 	 g e t  
 	 	 	 {  
 	 	 	 	 r e t u r n   C o n s o l e . F o r e g r o u n d C o l o r ;  
 	 	 	 }  
 	 	 	 s e t  
 	 	 	 {  
 	 	 	 	 C o n s o l e . F o r e g r o u n d C o l o r   =   v a l u e ;  
 	 	 	 }  
 " @   }   e l s e   { @ "  
 	 	 	 g e t  
 	 	 	 {  
 	 	 	 	 r e t u r n   n c F o r e g r o u n d C o l o r ;  
 	 	 	 }  
 	 	 	 s e t  
 	 	 	 {  
 	 	 	 	 n c F o r e g r o u n d C o l o r   =   v a l u e ;  
 	 	 	 }  
 " @   } )  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   B u f f e r C e l l [ , ]   G e t B u f f e r C o n t e n t s ( S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . R e c t a n g l e   r e c t a n g l e )  
 	 	 {  
 $ ( i f   ( $ c o m p i l e r 2 0 )   { @ "  
 	 	 	 t h r o w   n e w   E x c e p t i o n ( " M e t h o d   G e t B u f f e r C o n t e n t s   n o t   i m p l e m e n t e d   f o r   . N e t   V 2 . 0   c o m p i l e r " ) ;  
 " @   }   e l s e   {   i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 I n t P t r   h S t d O u t   =   G e t S t d H a n d l e ( S T D _ O U T P U T _ H A N D L E ) ;  
 	 	 	 C H A R _ I N F O [ , ]   b u f f e r   =   n e w   C H A R _ I N F O [ r e c t a n g l e . B o t t o m   -   r e c t a n g l e . T o p   +   1 ,   r e c t a n g l e . R i g h t   -   r e c t a n g l e . L e f t   +   1 ] ;  
 	 	 	 C O O R D   b u f f e r _ s i z e   =   n e w   C O O R D ( )   { X   =   ( s h o r t ) ( r e c t a n g l e . R i g h t   -   r e c t a n g l e . L e f t   +   1 ) ,   Y   =   ( s h o r t ) ( r e c t a n g l e . B o t t o m   -   r e c t a n g l e . T o p   +   1 ) } ;  
 	 	 	 C O O R D   b u f f e r _ i n d e x   =   n e w   C O O R D ( )   { X   =   0 ,   Y   =   0 } ;  
 	 	 	 S M A L L _ R E C T   s c r e e n _ r e c t   =   n e w   S M A L L _ R E C T ( )   { L e f t   =   ( s h o r t ) r e c t a n g l e . L e f t ,   T o p   =   ( s h o r t ) r e c t a n g l e . T o p ,   R i g h t   =   ( s h o r t ) r e c t a n g l e . R i g h t ,   B o t t o m   =   ( s h o r t ) r e c t a n g l e . B o t t o m } ;  
  
 	 	 	 R e a d C o n s o l e O u t p u t ( h S t d O u t ,   b u f f e r ,   b u f f e r _ s i z e ,   b u f f e r _ i n d e x ,   r e f   s c r e e n _ r e c t ) ;  
  
 	 	 	 S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . B u f f e r C e l l [ , ]   S c r e e n B u f f e r   =   n e w   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . B u f f e r C e l l [ r e c t a n g l e . B o t t o m   -   r e c t a n g l e . T o p   +   1 ,   r e c t a n g l e . R i g h t   -   r e c t a n g l e . L e f t   +   1 ] ;  
 	 	 	 f o r   ( i n t   y   =   0 ;   y   < =   r e c t a n g l e . B o t t o m   -   r e c t a n g l e . T o p ;   y + + )  
 	 	 	 	 f o r   ( i n t   x   =   0 ;   x   < =   r e c t a n g l e . R i g h t   -   r e c t a n g l e . L e f t ;   x + + )  
 	 	 	 	 {  
 	 	 	 	 	 S c r e e n B u f f e r [ y , x ]   =   n e w   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . B u f f e r C e l l ( b u f f e r [ y , x ] . A s c i i C h a r ,   ( S y s t e m . C o n s o l e C o l o r ) ( b u f f e r [ y , x ] . A t t r i b u t e s   &   0 x F ) ,   ( S y s t e m . C o n s o l e C o l o r ) ( ( b u f f e r [ y , x ] . A t t r i b u t e s   &   0 x F 0 )   /   0 x 1 0 ) ,   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . B u f f e r C e l l T y p e . C o m p l e t e ) ;  
 	 	 	 	 }  
  
 	 	 	 r e t u r n   S c r e e n B u f f e r ;  
 " @   }   e l s e   { @ "  
 	 	 	 S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . B u f f e r C e l l [ , ]   S c r e e n B u f f e r   =   n e w   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . B u f f e r C e l l [ r e c t a n g l e . B o t t o m   -   r e c t a n g l e . T o p   +   1 ,   r e c t a n g l e . R i g h t   -   r e c t a n g l e . L e f t   +   1 ] ;  
  
 	 	 	 f o r   ( i n t   y   =   0 ;   y   < =   r e c t a n g l e . B o t t o m   -   r e c t a n g l e . T o p ;   y + + )  
 	 	 	 	 f o r   ( i n t   x   =   0 ;   x   < =   r e c t a n g l e . R i g h t   -   r e c t a n g l e . L e f t ;   x + + )  
 	 	 	 	 {  
 	 	 	 	 	 S c r e e n B u f f e r [ y , x ]   =   n e w   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . B u f f e r C e l l ( '   ' ,   n c F o r e g r o u n d C o l o r ,   n c B a c k g r o u n d C o l o r ,   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . B u f f e r C e l l T y p e . C o m p l e t e ) ;  
 	 	 	 	 }  
  
 	 	 	 r e t u r n   S c r e e n B u f f e r ;  
 " @   }   } )  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   b o o l   K e y A v a i l a b l e  
 	 	 {  
 	 	 	 g e t  
 	 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 	 r e t u r n   C o n s o l e . K e y A v a i l a b l e ;  
 " @   }   e l s e   { @ "  
 	 	 	 	 r e t u r n   t r u e ;  
 " @   } )  
 	 	 	 }  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . S i z e   M a x P h y s i c a l W i n d o w S i z e  
 	 	 {  
 	 	 	 g e t  
 	 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e ) {   @ "  
 	 	 	 	 r e t u r n   n e w   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . S i z e ( C o n s o l e . L a r g e s t W i n d o w W i d t h ,   C o n s o l e . L a r g e s t W i n d o w H e i g h t ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 	 / /   D u m m y - W e r t   f � r   W i n f o r m s  
 	 	 	 	 r e t u r n   n e w   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . S i z e ( 2 4 0 ,   8 4 ) ;  
 " @   } )  
 	 	 	 }  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . S i z e   M a x W i n d o w S i z e  
 	 	 {  
 	 	 	 g e t  
 	 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e ) {   @ "  
 	 	 	 	 r e t u r n   n e w   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . S i z e ( C o n s o l e . B u f f e r W i d t h ,   C o n s o l e . B u f f e r W i d t h ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 	 / /   D u m m y - W e r t   f � r   W i n f o r m s  
 	 	 	 	 r e t u r n   n e w   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . S i z e ( 1 2 0 ,   8 4 ) ;  
 " @   } )  
 	 	 	 }  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   K e y I n f o   R e a d K e y ( R e a d K e y O p t i o n s   o p t i o n s )  
 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 C o n s o l e K e y I n f o   c k i   =   C o n s o l e . R e a d K e y ( ( o p t i o n s   &   R e a d K e y O p t i o n s . N o E c h o ) ! = 0 ) ;  
  
 	 	 	 C o n t r o l K e y S t a t e s   c k s   =   0 ;  
 	 	 	 i f   ( ( c k i . M o d i f i e r s   &   C o n s o l e M o d i f i e r s . A l t )   ! =   0 )  
 	 	 	 	 c k s   | =   C o n t r o l K e y S t a t e s . L e f t A l t P r e s s e d   |   C o n t r o l K e y S t a t e s . R i g h t A l t P r e s s e d ;  
 	 	 	 i f   ( ( c k i . M o d i f i e r s   &   C o n s o l e M o d i f i e r s . C o n t r o l )   ! =   0 )  
 	 	 	 	 c k s   | =   C o n t r o l K e y S t a t e s . L e f t C t r l P r e s s e d   |   C o n t r o l K e y S t a t e s . R i g h t C t r l P r e s s e d ;  
 	 	 	 i f   ( ( c k i . M o d i f i e r s   &   C o n s o l e M o d i f i e r s . S h i f t )   ! =   0 )  
 	 	 	 	 c k s   | =   C o n t r o l K e y S t a t e s . S h i f t P r e s s e d ;  
 	 	 	 i f   ( C o n s o l e . C a p s L o c k )  
 	 	 	 	 c k s   | =   C o n t r o l K e y S t a t e s . C a p s L o c k O n ;  
 	 	 	 i f   ( C o n s o l e . N u m b e r L o c k )  
 	 	 	 	 c k s   | =   C o n t r o l K e y S t a t e s . N u m L o c k O n ;  
  
 	 	 	 r e t u r n   n e w   K e y I n f o ( ( i n t ) c k i . K e y ,   c k i . K e y C h a r ,   c k s ,   ( o p t i o n s   &   R e a d K e y O p t i o n s . I n c l u d e K e y D o w n ) ! = 0 ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 i f   ( ( o p t i o n s   &   R e a d K e y O p t i o n s . I n c l u d e K e y D o w n ) ! = 0 )  
 	 	 	 	 r e t u r n   R e a d K e y B o x . S h o w ( " " ,   " " ,   t r u e ) ;  
 	 	 	 e l s e  
 	 	 	 	 r e t u r n   R e a d K e y B o x . S h o w ( " " ,   " " ,   f a l s e ) ;  
 " @   } )  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   v o i d   S c r o l l B u f f e r C o n t e n t s ( S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . R e c t a n g l e   s o u r c e ,   C o o r d i n a t e s   d e s t i n a t i o n ,   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . R e c t a n g l e   c l i p ,   B u f f e r C e l l   f i l l )  
 	 	 {   / /   n o   d e s t i n a t i o n   b l o c k   c l i p p i n g   i m p l e m e n t e d  
 $ ( i f   ( ! $ n o C o n s o l e )   {   i f   ( $ c o m p i l e r 2 0 )   { @ "  
 	 	 	 t h r o w   n e w   E x c e p t i o n ( " M e t h o d   S c r o l l B u f f e r C o n t e n t s   n o t   i m p l e m e n t e d   f o r   . N e t   V 2 . 0   c o m p i l e r " ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 / /   c l i p   a r e a   o u t   o f   s o u r c e   r a n g e ?  
 	 	 	 i f   ( ( s o u r c e . L e f t   >   c l i p . R i g h t )   | |   ( s o u r c e . R i g h t   <   c l i p . L e f t )   | |   ( s o u r c e . T o p   >   c l i p . B o t t o m )   | |   ( s o u r c e . B o t t o m   <   c l i p . T o p ) )  
 	 	 	 {   / /   c l i p p i n g   o u t   o f   r a n g e   - >   n o t h i n g   t o   d o  
 	 	 	 	 r e t u r n ;  
 	 	 	 }  
  
 	 	 	 I n t P t r   h S t d O u t   =   G e t S t d H a n d l e ( S T D _ O U T P U T _ H A N D L E ) ;  
 	 	 	 S M A L L _ R E C T   l p S c r o l l R e c t a n g l e   =   n e w   S M A L L _ R E C T ( )   { L e f t   =   ( s h o r t ) s o u r c e . L e f t ,   T o p   =   ( s h o r t ) s o u r c e . T o p ,   R i g h t   =   ( s h o r t ) ( s o u r c e . R i g h t ) ,   B o t t o m   =   ( s h o r t ) ( s o u r c e . B o t t o m ) } ;  
 	 	 	 S M A L L _ R E C T   l p C l i p R e c t a n g l e ;  
 	 	 	 i f   ( c l i p   ! =   n u l l )  
 	 	 	 {   l p C l i p R e c t a n g l e   =   n e w   S M A L L _ R E C T ( )   { L e f t   =   ( s h o r t ) c l i p . L e f t ,   T o p   =   ( s h o r t ) c l i p . T o p ,   R i g h t   =   ( s h o r t ) ( c l i p . R i g h t ) ,   B o t t o m   =   ( s h o r t ) ( c l i p . B o t t o m ) } ;   }  
 	 	 	 e l s e  
 	 	 	 {   l p C l i p R e c t a n g l e   =   n e w   S M A L L _ R E C T ( )   { L e f t   =   ( s h o r t ) 0 ,   T o p   =   ( s h o r t ) 0 ,   R i g h t   =   ( s h o r t ) ( C o n s o l e . W i n d o w W i d t h   -   1 ) ,   B o t t o m   =   ( s h o r t ) ( C o n s o l e . W i n d o w H e i g h t   -   1 ) } ;   }  
 	 	 	 C O O R D   d w D e s t i n a t i o n O r i g i n   =   n e w   C O O R D ( )   { X   =   ( s h o r t ) ( d e s t i n a t i o n . X ) ,   Y   =   ( s h o r t ) ( d e s t i n a t i o n . Y ) } ;  
 	 	 	 C H A R _ I N F O   l p F i l l   =   n e w   C H A R _ I N F O ( )   {   A s c i i C h a r   =   f i l l . C h a r a c t e r ,   A t t r i b u t e s   =   ( u s h o r t ) ( ( i n t ) ( f i l l . F o r e g r o u n d C o l o r )   +   ( i n t ) ( f i l l . B a c k g r o u n d C o l o r ) * 1 6 )   } ;  
  
 	 	 	 S c r o l l C o n s o l e S c r e e n B u f f e r ( h S t d O u t ,   r e f   l p S c r o l l R e c t a n g l e ,   r e f   l p C l i p R e c t a n g l e ,   d w D e s t i n a t i o n O r i g i n ,   r e f   l p F i l l ) ;  
 " @   }   } )  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   v o i d   S e t B u f f e r C o n t e n t s ( S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . R e c t a n g l e   r e c t a n g l e ,   B u f f e r C e l l   f i l l )  
 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e ) {   @ "  
 	 	 	 / /   u s i n g   a   t r i c k :   m o v e   t h e   b u f f e r   o u t   o f   t h e   s c r e e n ,   t h e   s o u r c e   a r e a   g e t s   f i l l e d   w i t h   t h e   c h a r   f i l l . C h a r a c t e r  
 	 	 	 i f   ( r e c t a n g l e . L e f t   > =   0 )  
 	 	 	 	 C o n s o l e . M o v e B u f f e r A r e a ( r e c t a n g l e . L e f t ,   r e c t a n g l e . T o p ,   r e c t a n g l e . R i g h t - r e c t a n g l e . L e f t + 1 ,   r e c t a n g l e . B o t t o m - r e c t a n g l e . T o p + 1 ,   B u f f e r S i z e . W i d t h ,   B u f f e r S i z e . H e i g h t ,   f i l l . C h a r a c t e r ,   f i l l . F o r e g r o u n d C o l o r ,   f i l l . B a c k g r o u n d C o l o r ) ;  
 	 	 	 e l s e  
 	 	 	 {   / /   C l e a r - H o s t :   m o v e   a l l   c o n t e n t   o f f   t h e   s c r e e n  
 	 	 	 	 C o n s o l e . M o v e B u f f e r A r e a ( 0 ,   0 ,   B u f f e r S i z e . W i d t h ,   B u f f e r S i z e . H e i g h t ,   B u f f e r S i z e . W i d t h ,   B u f f e r S i z e . H e i g h t ,   f i l l . C h a r a c t e r ,   f i l l . F o r e g r o u n d C o l o r ,   f i l l . B a c k g r o u n d C o l o r ) ;  
 	 	 	 }  
 " @   } )  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   v o i d   S e t B u f f e r C o n t e n t s ( C o o r d i n a t e s   o r i g i n ,   B u f f e r C e l l [ , ]   c o n t e n t s )  
 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   {   i f   ( $ c o m p i l e r 2 0 )   { @ "  
 	 	 	 t h r o w   n e w   E x c e p t i o n ( " M e t h o d   S e t B u f f e r C o n t e n t s   n o t   i m p l e m e n t e d   f o r   . N e t   V 2 . 0   c o m p i l e r " ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 I n t P t r   h S t d O u t   =   G e t S t d H a n d l e ( S T D _ O U T P U T _ H A N D L E ) ;  
 	 	 	 C H A R _ I N F O [ , ]   b u f f e r   =   n e w   C H A R _ I N F O [ c o n t e n t s . G e t L e n g t h ( 0 ) ,   c o n t e n t s . G e t L e n g t h ( 1 ) ] ;  
 	 	 	 C O O R D   b u f f e r _ s i z e   =   n e w   C O O R D ( )   { X   =   ( s h o r t ) ( c o n t e n t s . G e t L e n g t h ( 1 ) ) ,   Y   =   ( s h o r t ) ( c o n t e n t s . G e t L e n g t h ( 0 ) ) } ;  
 	 	 	 C O O R D   b u f f e r _ i n d e x   =   n e w   C O O R D ( )   { X   =   0 ,   Y   =   0 } ;  
 	 	 	 S M A L L _ R E C T   s c r e e n _ r e c t   =   n e w   S M A L L _ R E C T ( )   { L e f t   =   ( s h o r t ) o r i g i n . X ,   T o p   =   ( s h o r t ) o r i g i n . Y ,   R i g h t   =   ( s h o r t ) ( o r i g i n . X   +   c o n t e n t s . G e t L e n g t h ( 1 )   -   1 ) ,   B o t t o m   =   ( s h o r t ) ( o r i g i n . Y   +   c o n t e n t s . G e t L e n g t h ( 0 )   -   1 ) } ;  
  
 	 	 	 f o r   ( i n t   y   =   0 ;   y   <   c o n t e n t s . G e t L e n g t h ( 0 ) ;   y + + )  
 	 	 	 	 f o r   ( i n t   x   =   0 ;   x   <   c o n t e n t s . G e t L e n g t h ( 1 ) ;   x + + )  
 	 	 	 	 {  
 	 	 	 	 	 b u f f e r [ y , x ]   =   n e w   C H A R _ I N F O ( )   {   A s c i i C h a r   =   c o n t e n t s [ y , x ] . C h a r a c t e r ,   A t t r i b u t e s   =   ( u s h o r t ) ( ( i n t ) ( c o n t e n t s [ y , x ] . F o r e g r o u n d C o l o r )   +   ( i n t ) ( c o n t e n t s [ y , x ] . B a c k g r o u n d C o l o r ) * 1 6 )   } ;  
 	 	 	 	 }  
  
 	 	 	 W r i t e C o n s o l e O u t p u t ( h S t d O u t ,   b u f f e r ,   b u f f e r _ s i z e ,   b u f f e r _ i n d e x ,   r e f   s c r e e n _ r e c t ) ;  
 " @   }   } )  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   C o o r d i n a t e s   W i n d o w P o s i t i o n  
 	 	 {  
 	 	 	 g e t  
 	 	 	 {  
 	 	 	 	 C o o r d i n a t e s   s   =   n e w   C o o r d i n a t e s ( ) ;  
 $ ( i f   ( ! $ n o C o n s o l e ) {   @ "  
 	 	 	 	 s . X   =   C o n s o l e . W i n d o w L e f t ;  
 	 	 	 	 s . Y   =   C o n s o l e . W i n d o w T o p ;  
 " @   }   e l s e   { @ "  
 	 	 	 	 / /   D u m m y - W e r t   f � r   W i n f o r m s  
 	 	 	 	 s . X   =   0 ;  
 	 	 	 	 s . Y   =   0 ;  
 " @   } )  
 	 	 	 	 r e t u r n   s ;  
 	 	 	 }  
 	 	 	 s e t  
 	 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e ) {   @ "  
 	 	 	 	 C o n s o l e . W i n d o w L e f t   =   v a l u e . X ;  
 	 	 	 	 C o n s o l e . W i n d o w T o p   =   v a l u e . Y ;  
 " @   } )  
 	 	 	 }  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . S i z e   W i n d o w S i z e  
 	 	 {  
 	 	 	 g e t  
 	 	 	 {  
 	 	 	 	 S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . S i z e   s   =   n e w   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . H o s t . S i z e ( ) ;  
 $ ( i f   ( ! $ n o C o n s o l e ) {   @ "  
 	 	 	 	 s . H e i g h t   =   C o n s o l e . W i n d o w H e i g h t ;  
 	 	 	 	 s . W i d t h   =   C o n s o l e . W i n d o w W i d t h ;  
 " @   }   e l s e   { @ "  
 	 	 	 	 / /   D u m m y - W e r t   f � r   W i n f o r m s  
 	 	 	 	 s . H e i g h t   =   5 0 ;  
 	 	 	 	 s . W i d t h   =   1 2 0 ;  
 " @   } )  
 	 	 	 	 r e t u r n   s ;  
 	 	 	 }  
 	 	 	 s e t  
 	 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e ) {   @ "  
 	 	 	 	 C o n s o l e . W i n d o w W i d t h   =   v a l u e . W i d t h ;  
 	 	 	 	 C o n s o l e . W i n d o w H e i g h t   =   v a l u e . H e i g h t ;  
 " @   } )  
 	 	 	 }  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   s t r i n g   W i n d o w T i t l e  
 	 	 {  
 	 	 	 g e t  
 	 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e ) {   @ "  
 	 	 	 	 r e t u r n   C o n s o l e . T i t l e ;  
 " @   }   e l s e   { @ "  
 	 	 	 	 r e t u r n   S y s t e m . A p p D o m a i n . C u r r e n t D o m a i n . F r i e n d l y N a m e ;  
 " @   } )  
 	 	 	 }  
 	 	 	 s e t  
 	 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e ) {   @ "  
 	 	 	 	 C o n s o l e . T i t l e   =   v a l u e ;  
 " @   } )  
 	 	 	 }  
 	 	 }  
 	 }  
  
 $ ( i f   ( $ n o C o n s o l e ) {   @ "  
 	 p u b l i c   c l a s s   I n p u t B o x  
 	 {  
 	 	 [ D l l I m p o r t ( " u s e r 3 2 . d l l " ,   C h a r S e t   =   C h a r S e t . U n i c o d e ,   C a l l i n g C o n v e n t i o n   =   C a l l i n g C o n v e n t i o n . C d e c l ) ]  
 	 	 p r i v a t e   s t a t i c   e x t e r n   I n t P t r   M B _ G e t S t r i n g ( u i n t   s t r I d ) ;  
  
 	 	 p u b l i c   s t a t i c   D i a l o g R e s u l t   S h o w ( s t r i n g   s T i t l e ,   s t r i n g   s P r o m p t ,   r e f   s t r i n g   s V a l u e ,   b o o l   b S e c u r e )  
 	 	 {  
 	 	 	 / /   G e n e r a t e   c o n t r o l s  
 	 	 	 F o r m   f o r m   =   n e w   F o r m ( ) ;  
 	 	 	 L a b e l   l a b e l   =   n e w   L a b e l ( ) ;  
 	 	 	 T e x t B o x   t e x t B o x   =   n e w   T e x t B o x ( ) ;  
 	 	 	 B u t t o n   b u t t o n O k   =   n e w   B u t t o n ( ) ;  
 	 	 	 B u t t o n   b u t t o n C a n c e l   =   n e w   B u t t o n ( ) ;  
  
 	 	 	 / /   S i z e s   a n d   p o s i t i o n s   a r e   d e f i n e d   a c c o r d i n g   t o   t h e   l a b e l  
 	 	 	 / /   T h i s   c o n t r o l   h a s   t o   b e   f i n i s h e d   f i r s t  
 	 	 	 i f   ( s t r i n g . I s N u l l O r E m p t y ( s P r o m p t ) )  
 	 	 	 {  
 	 	 	 	 i f   ( b S e c u r e )  
 	 	 	 	 	 l a b e l . T e x t   =   " S e c u r e   i n p u t :       " ;  
 	 	 	 	 e l s e  
 	 	 	 	 	 l a b e l . T e x t   =   " I n p u t :                     " ;  
 	 	 	 }  
 	 	 	 e l s e  
 	 	 	 	 l a b e l . T e x t   =   s P r o m p t ;  
 	 	 	 l a b e l . L o c a t i o n   =   n e w   P o i n t ( 9 ,   1 9 ) ;  
 	 	 	 l a b e l . A u t o S i z e   =   t r u e ;  
 	 	 	 / /   S i z e   o f   t h e   l a b e l   i s   d e f i n e d   n o t   b e f o r e   A d d ( )  
 	 	 	 f o r m . C o n t r o l s . A d d ( l a b e l ) ;  
  
 	 	 	 / /   G e n e r a t e   t e x t b o x  
 	 	 	 i f   ( b S e c u r e )   t e x t B o x . U s e S y s t e m P a s s w o r d C h a r   =   t r u e ;  
 	 	 	 t e x t B o x . T e x t   =   s V a l u e ;  
 	 	 	 t e x t B o x . S e t B o u n d s ( 1 2 ,   l a b e l . B o t t o m ,   l a b e l . R i g h t   -   1 2 ,   2 0 ) ;  
  
 	 	 	 / /   G e n e r a t e   b u t t o n s  
 	 	 	 / /   g e t   l o c a l i z e d   " O K " - s t r i n g  
 	 	 	 s t r i n g   s T e x t O K   =   M a r s h a l . P t r T o S t r i n g U n i ( M B _ G e t S t r i n g ( 0 ) ) ;  
 	 	 	 i f   ( s t r i n g . I s N u l l O r E m p t y ( s T e x t O K ) )  
 	 	 	 	 b u t t o n O k . T e x t   =   " O K " ;  
 	 	 	 e l s e  
 	 	 	 	 b u t t o n O k . T e x t   =   s T e x t O K ;  
  
 	 	 	 / /   g e t   l o c a l i z e d   " C a n c e l " - s t r i n g  
 	 	 	 s t r i n g   s T e x t C a n c e l   =   M a r s h a l . P t r T o S t r i n g U n i ( M B _ G e t S t r i n g ( 1 ) ) ;  
 	 	 	 i f   ( s t r i n g . I s N u l l O r E m p t y ( s T e x t C a n c e l ) )  
 	 	 	 	 b u t t o n C a n c e l . T e x t   =   " C a n c e l " ;  
 	 	 	 e l s e  
 	 	 	 	 b u t t o n C a n c e l . T e x t   =   s T e x t C a n c e l ;  
  
 	 	 	 b u t t o n O k . D i a l o g R e s u l t   =   D i a l o g R e s u l t . O K ;  
 	 	 	 b u t t o n C a n c e l . D i a l o g R e s u l t   =   D i a l o g R e s u l t . C a n c e l ;  
 	 	 	 b u t t o n O k . S e t B o u n d s ( S y s t e m . M a t h . M a x ( 1 2 ,   l a b e l . R i g h t   -   1 5 8 ) ,   l a b e l . B o t t o m   +   3 6 ,   7 5 ,   2 3 ) ;  
 	 	 	 b u t t o n C a n c e l . S e t B o u n d s ( S y s t e m . M a t h . M a x ( 9 3 ,   l a b e l . R i g h t   -   7 7 ) ,   l a b e l . B o t t o m   +   3 6 ,   7 5 ,   2 3 ) ;  
  
 	 	 	 / /   C o n f i g u r e   f o r m  
 	 	 	 i f   ( s t r i n g . I s N u l l O r E m p t y ( s T i t l e ) )  
 	 	 	 	 f o r m . T e x t   =   S y s t e m . A p p D o m a i n . C u r r e n t D o m a i n . F r i e n d l y N a m e ;  
 	 	 	 e l s e  
 	 	 	 	 f o r m . T e x t   =   s T i t l e ;  
 	 	 	 f o r m . C l i e n t S i z e   =   n e w   S y s t e m . D r a w i n g . S i z e ( S y s t e m . M a t h . M a x ( 1 7 8 ,   l a b e l . R i g h t   +   1 0 ) ,   l a b e l . B o t t o m   +   7 1 ) ;  
 	 	 	 f o r m . C o n t r o l s . A d d R a n g e ( n e w   C o n t r o l [ ]   {   t e x t B o x ,   b u t t o n O k ,   b u t t o n C a n c e l   } ) ;  
 	 	 	 f o r m . F o r m B o r d e r S t y l e   =   F o r m B o r d e r S t y l e . F i x e d D i a l o g ;  
 	 	 	 f o r m . S t a r t P o s i t i o n   =   F o r m S t a r t P o s i t i o n . C e n t e r S c r e e n ;  
 	 	 	 f o r m . M i n i m i z e B o x   =   f a l s e ;  
 	 	 	 f o r m . M a x i m i z e B o x   =   f a l s e ;  
 	 	 	 f o r m . A c c e p t B u t t o n   =   b u t t o n O k ;  
 	 	 	 f o r m . C a n c e l B u t t o n   =   b u t t o n C a n c e l ;  
  
 	 	 	 / /   S h o w   f o r m   a n d   c o m p u t e   r e s u l t s  
 	 	 	 D i a l o g R e s u l t   d i a l o g R e s u l t   =   f o r m . S h o w D i a l o g ( ) ;  
 	 	 	 s V a l u e   =   t e x t B o x . T e x t ;  
 	 	 	 r e t u r n   d i a l o g R e s u l t ;  
 	 	 }  
  
 	 	 p u b l i c   s t a t i c   D i a l o g R e s u l t   S h o w ( s t r i n g   s T i t l e ,   s t r i n g   s P r o m p t ,   r e f   s t r i n g   s V a l u e )  
 	 	 {  
 	 	 	 r e t u r n   S h o w ( s T i t l e ,   s P r o m p t ,   r e f   s V a l u e ,   f a l s e ) ;  
 	 	 }  
 	 }  
  
 	 p u b l i c   c l a s s   C h o i c e B o x  
 	 {  
 	 	 p u b l i c   s t a t i c   i n t   S h o w ( S y s t e m . C o l l e c t i o n s . O b j e c t M o d e l . C o l l e c t i o n < C h o i c e D e s c r i p t i o n >   a A u s w a h l ,   i n t   i V o r g a b e ,   s t r i n g   s T i t l e ,   s t r i n g   s P r o m p t )  
 	 	 {  
 	 	 	 / /   c a n c e l   i f   a r r a y   i s   e m p t y  
 	 	 	 i f   ( a A u s w a h l   = =   n u l l )   r e t u r n   - 1 ;  
 	 	 	 i f   ( a A u s w a h l . C o u n t   <   1 )   r e t u r n   - 1 ;  
  
 	 	 	 / /   G e n e r a t e   c o n t r o l s  
 	 	 	 F o r m   f o r m   =   n e w   F o r m ( ) ;  
 	 	 	 R a d i o B u t t o n [ ]   a r a d i o B u t t o n   =   n e w   R a d i o B u t t o n [ a A u s w a h l . C o u n t ] ;  
 	 	 	 T o o l T i p   t o o l T i p   =   n e w   T o o l T i p ( ) ;  
 	 	 	 B u t t o n   b u t t o n O k   =   n e w   B u t t o n ( ) ;  
  
 	 	 	 / /   S i z e s   a n d   p o s i t i o n s   a r e   d e f i n e d   a c c o r d i n g   t o   t h e   l a b e l  
 	 	 	 / /   T h i s   c o n t r o l   h a s   t o   b e   f i n i s h e d   f i r s t   w h e n   a   p r o m p t   i s   a v a i l a b l e  
 	 	 	 i n t   i P o s Y   =   1 9 ,   i M a x X   =   0 ;  
 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( s P r o m p t ) )  
 	 	 	 {  
 	 	 	 	 L a b e l   l a b e l   =   n e w   L a b e l ( ) ;  
 	 	 	 	 l a b e l . T e x t   =   s P r o m p t ;  
 	 	 	 	 l a b e l . L o c a t i o n   =   n e w   P o i n t ( 9 ,   1 9 ) ;  
 	 	 	 	 l a b e l . A u t o S i z e   =   t r u e ;  
 	 	 	 	 / /   e r s t   d u r c h   A d d ( )   w i r d   d i e   G r � � e   d e s   L a b e l s   e r m i t t e l t  
 	 	 	 	 f o r m . C o n t r o l s . A d d ( l a b e l ) ;  
 	 	 	 	 i P o s Y   =   l a b e l . B o t t o m ;  
 	 	 	 	 i M a x X   =   l a b e l . R i g h t ;  
 	 	 	 }  
  
 	 	 	 / /   A n   d e n   R a d i o b u t t o n s   o r i e n t i e r e n   s i c h   d i e   w e i t e r e n   G r � � e n   u n d   P o s i t i o n e n  
 	 	 	 / /   D i e s e   C o n t r o l s   a l s o   j e t z t   f e r t i g s t e l l e n  
 	 	 	 i n t   C o u n t e r   =   0 ;  
 	 	 	 f o r e a c h   ( C h o i c e D e s c r i p t i o n   s A u s w a h l   i n   a A u s w a h l )  
 	 	 	 {  
 	 	 	 	 a r a d i o B u t t o n [ C o u n t e r ]   =   n e w   R a d i o B u t t o n ( ) ;  
 	 	 	 	 a r a d i o B u t t o n [ C o u n t e r ] . T e x t   =   s A u s w a h l . L a b e l ;  
 	 	 	 	 i f   ( C o u n t e r   = =   i V o r g a b e )  
 	 	 	 	 {   a r a d i o B u t t o n [ C o u n t e r ] . C h e c k e d   =   t r u e ;   }  
 	 	 	 	 a r a d i o B u t t o n [ C o u n t e r ] . L o c a t i o n   =   n e w   P o i n t ( 9 ,   i P o s Y ) ;  
 	 	 	 	 a r a d i o B u t t o n [ C o u n t e r ] . A u t o S i z e   =   t r u e ;  
 	 	 	 	 / /   e r s t   d u r c h   A d d ( )   w i r d   d i e   G r � � e   d e s   L a b e l s   e r m i t t e l t  
 	 	 	 	 f o r m . C o n t r o l s . A d d ( a r a d i o B u t t o n [ C o u n t e r ] ) ;  
 	 	 	 	 i P o s Y   =   a r a d i o B u t t o n [ C o u n t e r ] . B o t t o m ;  
 	 	 	 	 i f   ( a r a d i o B u t t o n [ C o u n t e r ] . R i g h t   >   i M a x X )   {   i M a x X   =   a r a d i o B u t t o n [ C o u n t e r ] . R i g h t ;   }  
 	 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( s A u s w a h l . H e l p M e s s a g e ) )  
 	 	 	 	 {  
 	 	 	 	 	   t o o l T i p . S e t T o o l T i p ( a r a d i o B u t t o n [ C o u n t e r ] ,   s A u s w a h l . H e l p M e s s a g e ) ;  
 	 	 	 	 }  
 	 	 	 	 C o u n t e r + + ;  
 	 	 	 }  
  
 	 	 	 / /   T o o l t i p   a u c h   a n z e i g e n ,   w e n n   P a r e n t - F e n s t e r   i n a k t i v   i s t  
 	 	 	 t o o l T i p . S h o w A l w a y s   =   t r u e ;  
  
 	 	 	 / /   B u t t o n   e r z e u g e n  
 	 	 	 b u t t o n O k . T e x t   =   " O K " ;  
 	 	 	 b u t t o n O k . D i a l o g R e s u l t   =   D i a l o g R e s u l t . O K ;  
 	 	 	 b u t t o n O k . S e t B o u n d s ( S y s t e m . M a t h . M a x ( 1 2 ,   i M a x X   -   7 7 ) ,   i P o s Y   +   3 6 ,   7 5 ,   2 3 ) ;  
  
 	 	 	 / /   c o n f i g u r e   f o r m  
 	 	 	 i f   ( s t r i n g . I s N u l l O r E m p t y ( s T i t l e ) )  
 	 	 	 	 f o r m . T e x t   =   S y s t e m . A p p D o m a i n . C u r r e n t D o m a i n . F r i e n d l y N a m e ;  
 	 	 	 e l s e  
 	 	 	 	 f o r m . T e x t   =   s T i t l e ;  
 	 	 	 f o r m . C l i e n t S i z e   =   n e w   S y s t e m . D r a w i n g . S i z e ( S y s t e m . M a t h . M a x ( 1 7 8 ,   i M a x X   +   1 0 ) ,   i P o s Y   +   7 1 ) ;  
 	 	 	 f o r m . C o n t r o l s . A d d ( b u t t o n O k ) ;  
 	 	 	 f o r m . F o r m B o r d e r S t y l e   =   F o r m B o r d e r S t y l e . F i x e d D i a l o g ;  
 	 	 	 f o r m . S t a r t P o s i t i o n   =   F o r m S t a r t P o s i t i o n . C e n t e r S c r e e n ;  
 	 	 	 f o r m . M i n i m i z e B o x   =   f a l s e ;  
 	 	 	 f o r m . M a x i m i z e B o x   =   f a l s e ;  
 	 	 	 f o r m . A c c e p t B u t t o n   =   b u t t o n O k ;  
  
 	 	 	 / /   s h o w   a n d   c o m p u t e   f o r m  
 	 	 	 i f   ( f o r m . S h o w D i a l o g ( )   = =   D i a l o g R e s u l t . O K )  
 	 	 	 {   i n t   i R u e c k   =   - 1 ;  
 	 	 	 	 f o r   ( C o u n t e r   =   0 ;   C o u n t e r   <   a A u s w a h l . C o u n t ;   C o u n t e r + + )  
 	 	 	 	 {  
 	 	 	 	 	 i f   ( a r a d i o B u t t o n [ C o u n t e r ] . C h e c k e d   = =   t r u e )  
 	 	 	 	 	 {   i R u e c k   =   C o u n t e r ;   }  
 	 	 	 	 }  
 	 	 	 	 r e t u r n   i R u e c k ;  
 	 	 	 }  
 	 	 	 e l s e  
 	 	 	 	 r e t u r n   - 1 ;  
 	 	 }  
 	 }  
  
 	 p u b l i c   c l a s s   R e a d K e y B o x  
 	 {  
 	 	 [ D l l I m p o r t ( " u s e r 3 2 . d l l " ) ]  
 	 	 p u b l i c   s t a t i c   e x t e r n   i n t   T o U n i c o d e ( u i n t   w V i r t K e y ,   u i n t   w S c a n C o d e ,   b y t e [ ]   l p K e y S t a t e ,  
 	 	 	 [ O u t ,   M a r s h a l A s ( U n m a n a g e d T y p e . L P W S t r ,   S i z e C o n s t   =   6 4 ) ]   S y s t e m . T e x t . S t r i n g B u i l d e r   p w s z B u f f ,  
 	 	 	 i n t   c c h B u f f ,   u i n t   w F l a g s ) ;  
  
 	 	 s t a t i c   s t r i n g   G e t C h a r F r o m K e y s ( K e y s   k e y s ,   b o o l   b S h i f t ,   b o o l   b A l t G r )  
 	 	 {  
 	 	 	 S y s t e m . T e x t . S t r i n g B u i l d e r   b u f f e r   =   n e w   S y s t e m . T e x t . S t r i n g B u i l d e r ( 6 4 ) ;  
 	 	 	 b y t e [ ]   k e y b o a r d S t a t e   =   n e w   b y t e [ 2 5 6 ] ;  
 	 	 	 i f   ( b S h i f t )  
 	 	 	 {   k e y b o a r d S t a t e [ ( i n t )   K e y s . S h i f t K e y ]   =   0 x f f ;   }  
 	 	 	 i f   ( b A l t G r )  
 	 	 	 {   k e y b o a r d S t a t e [ ( i n t )   K e y s . C o n t r o l K e y ]   =   0 x f f ;  
 	 	 	 	 k e y b o a r d S t a t e [ ( i n t )   K e y s . M e n u ]   =   0 x f f ;  
 	 	 	 }  
 	 	 	 i f   ( T o U n i c o d e ( ( u i n t )   k e y s ,   0 ,   k e y b o a r d S t a t e ,   b u f f e r ,   6 4 ,   0 )   > =   1 )  
 	 	 	 	 r e t u r n   b u f f e r . T o S t r i n g ( ) ;  
 	 	 	 e l s e  
 	 	 	 	 r e t u r n   " \ 0 " ;  
 	 	 }  
  
 	 	 c l a s s   K e y b o a r d F o r m   :   F o r m  
 	 	 {  
 	 	 	 p u b l i c   K e y b o a r d F o r m ( )  
 	 	 	 {  
 	 	 	 	 t h i s . K e y D o w n   + =   n e w   K e y E v e n t H a n d l e r ( K e y b o a r d F o r m _ K e y D o w n ) ;  
 	 	 	 	 t h i s . K e y U p   + =   n e w   K e y E v e n t H a n d l e r ( K e y b o a r d F o r m _ K e y U p ) ;  
 	 	 	 }  
  
 	 	 	 / /   c h e c k   f o r   K e y D o w n   o r   K e y U p ?  
 	 	 	 p u b l i c   b o o l   c h e c k K e y D o w n   =   t r u e ;  
 	 	 	 / /   k e y   c o d e   f o r   p r e s s e d   k e y  
 	 	 	 p u b l i c   K e y I n f o   k e y i n f o ;  
  
 	 	 	 v o i d   K e y b o a r d F o r m _ K e y D o w n ( o b j e c t   s e n d e r ,   K e y E v e n t A r g s   e )  
 	 	 	 {  
 	 	 	 	 i f   ( c h e c k K e y D o w n )  
 	 	 	 	 {   / /   s t o r e   k e y   i n f o  
 	 	 	 	 	 k e y i n f o . V i r t u a l K e y C o d e   =   e . K e y V a l u e ;  
 	 	 	 	 	 k e y i n f o . C h a r a c t e r   =   G e t C h a r F r o m K e y s ( e . K e y C o d e ,   e . S h i f t ,   e . A l t   &   e . C o n t r o l ) [ 0 ] ;  
 	 	 	 	 	 k e y i n f o . K e y D o w n   =   f a l s e ;  
 	 	 	 	 	 k e y i n f o . C o n t r o l K e y S t a t e   =   0 ;  
 	 	 	 	 	 i f   ( e . A l t )   {   k e y i n f o . C o n t r o l K e y S t a t e   =   C o n t r o l K e y S t a t e s . L e f t A l t P r e s s e d   |   C o n t r o l K e y S t a t e s . R i g h t A l t P r e s s e d ;   }  
 	 	 	 	 	 i f   ( e . C o n t r o l )  
 	 	 	 	 	 {   k e y i n f o . C o n t r o l K e y S t a t e   | =   C o n t r o l K e y S t a t e s . L e f t C t r l P r e s s e d   |   C o n t r o l K e y S t a t e s . R i g h t C t r l P r e s s e d ;  
 	 	 	 	 	 	 i f   ( ! e . A l t )  
 	 	 	 	 	 	 {   i f   ( e . K e y V a l u e   >   6 4   & &   e . K e y V a l u e   <   9 6 )   k e y i n f o . C h a r a c t e r   =   ( c h a r ) ( e . K e y V a l u e   -   6 4 ) ;   }  
 	 	 	 	 	 }  
 	 	 	 	 	 i f   ( e . S h i f t )   {   k e y i n f o . C o n t r o l K e y S t a t e   | =   C o n t r o l K e y S t a t e s . S h i f t P r e s s e d ;   }  
 	 	 	 	 	 i f   ( ( e . M o d i f i e r s   &   S y s t e m . W i n d o w s . F o r m s . K e y s . C a p s L o c k )   >   0 )   {   k e y i n f o . C o n t r o l K e y S t a t e   | =   C o n t r o l K e y S t a t e s . C a p s L o c k O n ;   }  
 	 	 	 	 	 i f   ( ( e . M o d i f i e r s   &   S y s t e m . W i n d o w s . F o r m s . K e y s . N u m L o c k )   >   0 )   {   k e y i n f o . C o n t r o l K e y S t a t e   | =   C o n t r o l K e y S t a t e s . N u m L o c k O n ;   }  
 	 	 	 	 	 / /   a n d   c l o s e   t h e   f o r m  
 	 	 	 	 	 t h i s . C l o s e ( ) ;  
 	 	 	 	 }  
 	 	 	 }  
  
 	 	 	 v o i d   K e y b o a r d F o r m _ K e y U p ( o b j e c t   s e n d e r ,   K e y E v e n t A r g s   e )  
 	 	 	 {  
 	 	 	 	 i f   ( ! c h e c k K e y D o w n )  
 	 	 	 	 {   / /   s t o r e   k e y   i n f o  
 	 	 	 	 	 k e y i n f o . V i r t u a l K e y C o d e   =   e . K e y V a l u e ;  
 	 	 	 	 	 k e y i n f o . C h a r a c t e r   =   G e t C h a r F r o m K e y s ( e . K e y C o d e ,   e . S h i f t ,   e . A l t   &   e . C o n t r o l ) [ 0 ] ;  
 	 	 	 	 	 k e y i n f o . K e y D o w n   =   t r u e ;  
 	 	 	 	 	 k e y i n f o . C o n t r o l K e y S t a t e   =   0 ;  
 	 	 	 	 	 i f   ( e . A l t )   {   k e y i n f o . C o n t r o l K e y S t a t e   =   C o n t r o l K e y S t a t e s . L e f t A l t P r e s s e d   |   C o n t r o l K e y S t a t e s . R i g h t A l t P r e s s e d ;   }  
 	 	 	 	 	 i f   ( e . C o n t r o l )  
 	 	 	 	 	 {   k e y i n f o . C o n t r o l K e y S t a t e   | =   C o n t r o l K e y S t a t e s . L e f t C t r l P r e s s e d   |   C o n t r o l K e y S t a t e s . R i g h t C t r l P r e s s e d ;  
 	 	 	 	 	 	 i f   ( ! e . A l t )  
 	 	 	 	 	 	 {   i f   ( e . K e y V a l u e   >   6 4   & &   e . K e y V a l u e   <   9 6 )   k e y i n f o . C h a r a c t e r   =   ( c h a r ) ( e . K e y V a l u e   -   6 4 ) ;   }  
 	 	 	 	 	 }  
 	 	 	 	 	 i f   ( e . S h i f t )   {   k e y i n f o . C o n t r o l K e y S t a t e   | =   C o n t r o l K e y S t a t e s . S h i f t P r e s s e d ;   }  
 	 	 	 	 	 i f   ( ( e . M o d i f i e r s   &   S y s t e m . W i n d o w s . F o r m s . K e y s . C a p s L o c k )   >   0 )   {   k e y i n f o . C o n t r o l K e y S t a t e   | =   C o n t r o l K e y S t a t e s . C a p s L o c k O n ;   }  
 	 	 	 	 	 i f   ( ( e . M o d i f i e r s   &   S y s t e m . W i n d o w s . F o r m s . K e y s . N u m L o c k )   >   0 )   {   k e y i n f o . C o n t r o l K e y S t a t e   | =   C o n t r o l K e y S t a t e s . N u m L o c k O n ;   }  
 	 	 	 	 	 / /   a n d   c l o s e   t h e   f o r m  
 	 	 	 	 	 t h i s . C l o s e ( ) ;  
 	 	 	 	 }  
 	 	 	 }  
 	 	 }  
  
 	 	 p u b l i c   s t a t i c   K e y I n f o   S h o w ( s t r i n g   s T i t l e ,   s t r i n g   s P r o m p t ,   b o o l   b I n c l u d e K e y D o w n )  
 	 	 {  
 	 	 	 / /   C o n t r o l s   e r z e u g e n  
 	 	 	 K e y b o a r d F o r m   f o r m   =   n e w   K e y b o a r d F o r m ( ) ;  
 	 	 	 L a b e l   l a b e l   =   n e w   L a b e l ( ) ;  
  
 	 	 	 / /   A m   L a b e l   o r i e n t i e r e n   s i c h   d i e   G r � � e n   u n d   P o s i t i o n e n  
 	 	 	 / /   D i e s e s   C o n t r o l   a l s o   z u e r s t   f e r t i g s t e l l e n  
 	 	 	 i f   ( s t r i n g . I s N u l l O r E m p t y ( s P r o m p t ) )  
 	 	 	 {  
 	 	 	 	 	 l a b e l . T e x t   =   " P r e s s   a   k e y " ;  
 	 	 	 }  
 	 	 	 e l s e  
 	 	 	 	 l a b e l . T e x t   =   s P r o m p t ;  
 	 	 	 l a b e l . L o c a t i o n   =   n e w   P o i n t ( 9 ,   1 9 ) ;  
 	 	 	 l a b e l . A u t o S i z e   =   t r u e ;  
 	 	 	 / /   e r s t   d u r c h   A d d ( )   w i r d   d i e   G r � � e   d e s   L a b e l s   e r m i t t e l t  
 	 	 	 f o r m . C o n t r o l s . A d d ( l a b e l ) ;  
  
 	 	 	 / /   c o n f i g u r e   f o r m  
 	 	 	 i f   ( s t r i n g . I s N u l l O r E m p t y ( s T i t l e ) )  
 	 	 	 	 f o r m . T e x t   =   S y s t e m . A p p D o m a i n . C u r r e n t D o m a i n . F r i e n d l y N a m e ;  
 	 	 	 e l s e  
 	 	 	 	 f o r m . T e x t   =   s T i t l e ;  
 	 	 	 f o r m . C l i e n t S i z e   =   n e w   S y s t e m . D r a w i n g . S i z e ( S y s t e m . M a t h . M a x ( 1 7 8 ,   l a b e l . R i g h t   +   1 0 ) ,   l a b e l . B o t t o m   +   5 5 ) ;  
 	 	 	 f o r m . F o r m B o r d e r S t y l e   =   F o r m B o r d e r S t y l e . F i x e d D i a l o g ;  
 	 	 	 f o r m . S t a r t P o s i t i o n   =   F o r m S t a r t P o s i t i o n . C e n t e r S c r e e n ;  
 	 	 	 f o r m . M i n i m i z e B o x   =   f a l s e ;  
 	 	 	 f o r m . M a x i m i z e B o x   =   f a l s e ;  
  
 	 	 	 / /   s h o w   a n d   c o m p u t e   f o r m  
 	 	 	 f o r m . c h e c k K e y D o w n   =   b I n c l u d e K e y D o w n ;  
 	 	 	 f o r m . S h o w D i a l o g ( ) ;  
 	 	 	 r e t u r n   f o r m . k e y i n f o ;  
 	 	 }  
 	 }  
  
 	 p u b l i c   c l a s s   P r o g r e s s F o r m   :   F o r m  
 	 {  
 	 	 p r i v a t e   L a b e l   o b j L b l A c t i v i t y ;  
 	 	 p r i v a t e   L a b e l   o b j L b l S t a t u s ;  
 	 	 p r i v a t e   P r o g r e s s B a r   o b j P r o g r e s s B a r ;  
 	 	 p r i v a t e   L a b e l   o b j L b l R e m a i n i n g T i m e ;  
 	 	 p r i v a t e   L a b e l   o b j L b l O p e r a t i o n ;  
 	 	 p r i v a t e   C o n s o l e C o l o r   P r o g r e s s B a r C o l o r   =   C o n s o l e C o l o r . D a r k C y a n ;  
  
 	 	 p r i v a t e   C o l o r   D r a w i n g C o l o r ( C o n s o l e C o l o r   c o l o r )  
 	 	 {     / /   c o n v e r t   C o n s o l e C o l o r   t o   S y s t e m . D r a w i n g . C o l o r  
 	 	 	 s w i t c h   ( c o l o r )  
 	 	 	 {  
 	 	 	 	 c a s e   C o n s o l e C o l o r . B l a c k :   r e t u r n   C o l o r . B l a c k ;  
 	 	 	 	 c a s e   C o n s o l e C o l o r . B l u e :   r e t u r n   C o l o r . B l u e ;  
 	 	 	 	 c a s e   C o n s o l e C o l o r . C y a n :   r e t u r n   C o l o r . C y a n ;  
 	 	 	 	 c a s e   C o n s o l e C o l o r . D a r k B l u e :   r e t u r n   C o l o r T r a n s l a t o r . F r o m H t m l ( " # 0 0 0 0 8 0 " ) ;  
 	 	 	 	 c a s e   C o n s o l e C o l o r . D a r k G r a y :   r e t u r n   C o l o r T r a n s l a t o r . F r o m H t m l ( " # 8 0 8 0 8 0 " ) ;  
 	 	 	 	 c a s e   C o n s o l e C o l o r . D a r k G r e e n :   r e t u r n   C o l o r T r a n s l a t o r . F r o m H t m l ( " # 0 0 8 0 0 0 " ) ;  
 	 	 	 	 c a s e   C o n s o l e C o l o r . D a r k C y a n :   r e t u r n   C o l o r T r a n s l a t o r . F r o m H t m l ( " # 0 0 8 0 8 0 " ) ;  
 	 	 	 	 c a s e   C o n s o l e C o l o r . D a r k M a g e n t a :   r e t u r n   C o l o r T r a n s l a t o r . F r o m H t m l ( " # 8 0 0 0 8 0 " ) ;  
 	 	 	 	 c a s e   C o n s o l e C o l o r . D a r k R e d :   r e t u r n   C o l o r T r a n s l a t o r . F r o m H t m l ( " # 8 0 0 0 0 0 " ) ;  
 	 	 	 	 c a s e   C o n s o l e C o l o r . D a r k Y e l l o w :   r e t u r n   C o l o r T r a n s l a t o r . F r o m H t m l ( " # 8 0 8 0 0 0 " ) ;  
 	 	 	 	 c a s e   C o n s o l e C o l o r . G r a y :   r e t u r n   C o l o r T r a n s l a t o r . F r o m H t m l ( " # C 0 C 0 C 0 " ) ;  
 	 	 	 	 c a s e   C o n s o l e C o l o r . G r e e n :   r e t u r n   C o l o r T r a n s l a t o r . F r o m H t m l ( " # 0 0 F F 0 0 " ) ;  
 	 	 	 	 c a s e   C o n s o l e C o l o r . M a g e n t a :   r e t u r n   C o l o r . M a g e n t a ;  
 	 	 	 	 c a s e   C o n s o l e C o l o r . R e d :   r e t u r n   C o l o r . R e d ;  
 	 	 	 	 c a s e   C o n s o l e C o l o r . W h i t e :   r e t u r n   C o l o r . W h i t e ;  
 	 	 	 	 d e f a u l t :   r e t u r n   C o l o r . Y e l l o w ;  
 	 	 	 }  
 	 	 }  
  
 	 	 p r i v a t e   v o i d   I n i t i a l i z e C o m p o n e n t ( )  
 	 	 {  
 	 	 	 t h i s . S u s p e n d L a y o u t ( ) ;  
  
 	 	 	 t h i s . T e x t   =   " P r o g r e s s " ;  
 	 	 	 t h i s . H e i g h t   =   1 6 0 ;  
 	 	 	 t h i s . W i d t h   =   8 0 0 ;  
 	 	 	 t h i s . B a c k C o l o r   =   C o l o r . W h i t e ;  
 	 	 	 t h i s . F o r m B o r d e r S t y l e   =   F o r m B o r d e r S t y l e . F i x e d S i n g l e ;  
 	 	 	 t h i s . C o n t r o l B o x   =   f a l s e ;  
 	 	 	 t h i s . S t a r t P o s i t i o n   =   F o r m S t a r t P o s i t i o n . C e n t e r S c r e e n ;  
  
 	 	 	 / /   C r e a t e   L a b e l  
 	 	 	 o b j L b l A c t i v i t y   =   n e w   L a b e l ( ) ;  
 	 	 	 o b j L b l A c t i v i t y . L e f t   =   5 ;  
 	 	 	 o b j L b l A c t i v i t y . T o p   =   1 0 ;  
 	 	 	 o b j L b l A c t i v i t y . W i d t h   =   8 0 0   -   2 0 ;  
 	 	 	 o b j L b l A c t i v i t y . H e i g h t   =   1 6 ;  
 	 	 	 o b j L b l A c t i v i t y . F o n t   =   n e w   F o n t ( o b j L b l A c t i v i t y . F o n t ,   F o n t S t y l e . B o l d ) ;  
 	 	 	 o b j L b l A c t i v i t y . T e x t   =   " " ;  
 	 	 	 / /   A d d   L a b e l   t o   F o r m  
 	 	 	 t h i s . C o n t r o l s . A d d ( o b j L b l A c t i v i t y ) ;  
  
 	 	 	 / /   C r e a t e   L a b e l  
 	 	 	 o b j L b l S t a t u s   =   n e w   L a b e l ( ) ;  
 	 	 	 o b j L b l S t a t u s . L e f t   =   2 5 ;  
 	 	 	 o b j L b l S t a t u s . T o p   =   2 6 ;  
 	 	 	 o b j L b l S t a t u s . W i d t h   =   8 0 0   -   4 0 ;  
 	 	 	 o b j L b l S t a t u s . H e i g h t   =   1 6 ;  
 	 	 	 o b j L b l S t a t u s . T e x t   =   " " ;  
 	 	 	 / /   A d d   L a b e l   t o   F o r m  
 	 	 	 t h i s . C o n t r o l s . A d d ( o b j L b l S t a t u s ) ;  
  
 	 	 	 / /   C r e a t e   P r o g r e s s B a r  
 	 	 	 o b j P r o g r e s s B a r   =   n e w   P r o g r e s s B a r ( ) ;  
 	 	 	 o b j P r o g r e s s B a r . V a l u e   =   0 ;  
 	 	 	 o b j P r o g r e s s B a r . S t y l e   =   P r o g r e s s B a r S t y l e . C o n t i n u o u s ;  
 	 	 	 o b j P r o g r e s s B a r . F o r e C o l o r   =   D r a w i n g C o l o r ( P r o g r e s s B a r C o l o r ) ;  
 	 	 	 o b j P r o g r e s s B a r . S i z e   =   n e w   S y s t e m . D r a w i n g . S i z e ( 8 0 0   -   6 0 ,   2 0 ) ;  
 	 	 	 o b j P r o g r e s s B a r . L e f t   =   2 5 ;  
 	 	 	 o b j P r o g r e s s B a r . T o p   =   5 5 ;  
 	 	 	 / /   A d d   P r o g r e s s B a r   t o   F o r m  
 	 	 	 t h i s . C o n t r o l s . A d d ( o b j P r o g r e s s B a r ) ;  
  
 	 	 	 / /   C r e a t e   L a b e l  
 	 	 	 o b j L b l R e m a i n i n g T i m e   =   n e w   L a b e l ( ) ;  
 	 	 	 o b j L b l R e m a i n i n g T i m e . L e f t   =   5 ;  
 	 	 	 o b j L b l R e m a i n i n g T i m e . T o p   =   8 5 ;  
 	 	 	 o b j L b l R e m a i n i n g T i m e . W i d t h   =   8 0 0   -   2 0 ;  
 	 	 	 o b j L b l R e m a i n i n g T i m e . H e i g h t   =   1 6 ;  
 	 	 	 o b j L b l R e m a i n i n g T i m e . T e x t   =   " " ;  
 	 	 	 / /   A d d   L a b e l   t o   F o r m  
 	 	 	 t h i s . C o n t r o l s . A d d ( o b j L b l R e m a i n i n g T i m e ) ;  
  
 	 	 	 / /   C r e a t e   L a b e l  
 	 	 	 o b j L b l O p e r a t i o n   =   n e w   L a b e l ( ) ;  
 	 	 	 o b j L b l O p e r a t i o n . L e f t   =   2 5 ;  
 	 	 	 o b j L b l O p e r a t i o n . T o p   =   1 0 1 ;  
 	 	 	 o b j L b l O p e r a t i o n . W i d t h   =   8 0 0   -   4 0 ;  
 	 	 	 o b j L b l O p e r a t i o n . H e i g h t   =   1 6 ;  
 	 	 	 o b j L b l O p e r a t i o n . T e x t   =   " " ;  
 	 	 	 / /   A d d   L a b e l   t o   F o r m  
 	 	 	 t h i s . C o n t r o l s . A d d ( o b j L b l O p e r a t i o n ) ;  
  
 	 	 	 t h i s . R e s u m e L a y o u t ( ) ;  
 	 	 }  
  
 	 	 p u b l i c   P r o g r e s s F o r m ( )  
 	 	 {  
 	 	 	 I n i t i a l i z e C o m p o n e n t ( ) ;  
 	 	 }  
  
 	 	 p u b l i c   P r o g r e s s F o r m ( C o n s o l e C o l o r   B a r C o l o r )  
 	 	 {  
 	 	 	 P r o g r e s s B a r C o l o r   =   B a r C o l o r ;  
 	 	 	 I n i t i a l i z e C o m p o n e n t ( ) ;  
 	 	 }  
  
 	 	 p u b l i c   v o i d   U p d a t e ( P r o g r e s s R e c o r d   o b j R e c o r d )  
 	 	 {  
 	 	 	 i f   ( o b j R e c o r d   = =   n u l l )  
 	 	 	 	 r e t u r n ;  
  
 	 	 	 i f   ( o b j R e c o r d . R e c o r d T y p e   = =   P r o g r e s s R e c o r d T y p e . C o m p l e t e d )  
 	 	 	 {  
 	 	 	 	 t h i s . C l o s e ( ) ;  
 	 	 	 	 r e t u r n ;  
 	 	 	 }  
  
 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( o b j R e c o r d . A c t i v i t y ) )  
 	 	 	 	 o b j L b l A c t i v i t y . T e x t   =   o b j R e c o r d . A c t i v i t y ;  
 	 	 	 e l s e  
 	 	 	 	 o b j L b l A c t i v i t y . T e x t   =   " " ;  
  
 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( o b j R e c o r d . S t a t u s D e s c r i p t i o n ) )  
 	 	 	 	 o b j L b l S t a t u s . T e x t   =   o b j R e c o r d . S t a t u s D e s c r i p t i o n ;  
 	 	 	 e l s e  
 	 	 	 	 o b j L b l S t a t u s . T e x t   =   " " ;  
  
 	 	 	 i f   ( ( o b j R e c o r d . P e r c e n t C o m p l e t e   > =   0 )   & &   ( o b j R e c o r d . P e r c e n t C o m p l e t e   < =   1 0 0 ) )  
 	 	 	 {  
 	 	 	 	 o b j P r o g r e s s B a r . V a l u e   =   o b j R e c o r d . P e r c e n t C o m p l e t e ;  
 	 	 	 	 o b j P r o g r e s s B a r . V i s i b l e   =   t r u e ;  
 	 	 	 }  
 	 	 	 e l s e  
 	 	 	 {   i f   ( o b j R e c o r d . P e r c e n t C o m p l e t e   >   1 0 0 )  
 	 	 	 	 {  
 	 	 	 	 	 o b j P r o g r e s s B a r . V a l u e   =   0 ;  
 	 	 	 	 	 o b j P r o g r e s s B a r . V i s i b l e   =   t r u e ;  
 	 	 	 	 }  
 	 	 	 	 e l s e  
 	 	 	 	 	 o b j P r o g r e s s B a r . V i s i b l e   =   f a l s e ;  
 	 	 	 }  
  
 	 	 	 i f   ( o b j R e c o r d . S e c o n d s R e m a i n i n g   > =   0 )  
 	 	 	 {  
 	 	 	 	 S y s t e m . T i m e S p a n   o b j T i m e S p a n   =   n e w   S y s t e m . T i m e S p a n ( 0 ,   0 ,   o b j R e c o r d . S e c o n d s R e m a i n i n g ) ;  
 	 	 	 	 o b j L b l R e m a i n i n g T i m e . T e x t   =   " R e m a i n i n g   t i m e :   "   +   s t r i n g . F o r m a t ( " { 0 : 0 0 } : { 1 : 0 0 } : { 2 : 0 0 } " ,   ( i n t ) o b j T i m e S p a n . T o t a l H o u r s ,   o b j T i m e S p a n . M i n u t e s ,   o b j T i m e S p a n . S e c o n d s ) ;  
 	 	 	 }  
 	 	 	 e l s e  
 	 	 	 	 o b j L b l R e m a i n i n g T i m e . T e x t   =   " " ;  
  
 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( o b j R e c o r d . C u r r e n t O p e r a t i o n ) )  
 	 	 	 	 o b j L b l O p e r a t i o n . T e x t   =   o b j R e c o r d . C u r r e n t O p e r a t i o n ;  
 	 	 	 e l s e  
 	 	 	 	 o b j L b l O p e r a t i o n . T e x t   =   " " ;  
  
 	 	 	 t h i s . R e f r e s h ( ) ;  
 	 	 	 A p p l i c a t i o n . D o E v e n t s ( ) ;  
 	 	 }  
 	 }  
 " @ } )  
  
 	 / /   d e f i n e   I s I n p u t R e d i r e c t e d ( ) ,   I s O u t p u t R e d i r e c t e d ( )   a n d   I s E r r o r R e d i r e c t e d ( )   h e r e   s i n c e   t h e y   w e r e   i n t r o d u c e d   f i r s t   w i t h   . N e t   4 . 5  
 	 p u b l i c   c l a s s   C o n s o l e I n f o  
 	 {  
 	 	 p r i v a t e   e n u m   F i l e T y p e   :   u i n t  
 	 	 {  
 	 	 	 F I L E _ T Y P E _ U N K N O W N   =   0 x 0 0 0 0 ,  
 	 	 	 F I L E _ T Y P E _ D I S K   =   0 x 0 0 0 1 ,  
 	 	 	 F I L E _ T Y P E _ C H A R   =   0 x 0 0 0 2 ,  
 	 	 	 F I L E _ T Y P E _ P I P E   =   0 x 0 0 0 3 ,  
 	 	 	 F I L E _ T Y P E _ R E M O T E   =   0 x 8 0 0 0  
 	 	 }  
  
 	 	 p r i v a t e   e n u m   S T D H a n d l e   :   u i n t  
 	 	 {  
 	 	 	 S T D _ I N P U T _ H A N D L E   =   u n c h e c k e d ( ( u i n t ) - 1 0 ) ,  
 	 	 	 S T D _ O U T P U T _ H A N D L E   =   u n c h e c k e d ( ( u i n t ) - 1 1 ) ,  
 	 	 	 S T D _ E R R O R _ H A N D L E   =   u n c h e c k e d ( ( u i n t ) - 1 2 )  
 	 	 }  
  
 	 	 [ D l l I m p o r t ( " K e r n e l 3 2 . d l l " ) ]  
 	 	 s t a t i c   p r i v a t e   e x t e r n   U I n t P t r   G e t S t d H a n d l e ( S T D H a n d l e   s t d H a n d l e ) ;  
  
 	 	 [ D l l I m p o r t ( " K e r n e l 3 2 . d l l " ) ]  
 	 	 s t a t i c   p r i v a t e   e x t e r n   F i l e T y p e   G e t F i l e T y p e ( U I n t P t r   h F i l e ) ;  
  
 	 	 s t a t i c   p u b l i c   b o o l   I s I n p u t R e d i r e c t e d ( )  
 	 	 {  
 	 	 	 U I n t P t r   h I n p u t   =   G e t S t d H a n d l e ( S T D H a n d l e . S T D _ I N P U T _ H A N D L E ) ;  
 	 	 	 F i l e T y p e   f i l e T y p e   =   ( F i l e T y p e ) G e t F i l e T y p e ( h I n p u t ) ;  
 	 	 	 i f   ( ( f i l e T y p e   = =   F i l e T y p e . F I L E _ T Y P E _ C H A R )   | |   ( f i l e T y p e   = =   F i l e T y p e . F I L E _ T Y P E _ U N K N O W N ) )  
 	 	 	 	 r e t u r n   f a l s e ;  
 	 	 	 r e t u r n   t r u e ;  
 	 	 }  
  
 	 	 s t a t i c   p u b l i c   b o o l   I s O u t p u t R e d i r e c t e d ( )  
 	 	 {  
 	 	 	 U I n t P t r   h O u t p u t   =   G e t S t d H a n d l e ( S T D H a n d l e . S T D _ O U T P U T _ H A N D L E ) ;  
 	 	 	 F i l e T y p e   f i l e T y p e   =   ( F i l e T y p e ) G e t F i l e T y p e ( h O u t p u t ) ;  
 	 	 	 i f   ( ( f i l e T y p e   = =   F i l e T y p e . F I L E _ T Y P E _ C H A R )   | |   ( f i l e T y p e   = =   F i l e T y p e . F I L E _ T Y P E _ U N K N O W N ) )  
 	 	 	 	 r e t u r n   f a l s e ;  
 	 	 	 r e t u r n   t r u e ;  
 	 	 }  
  
 	 	 s t a t i c   p u b l i c   b o o l   I s E r r o r R e d i r e c t e d ( )  
 	 	 {  
 	 	 	 U I n t P t r   h E r r o r   =   G e t S t d H a n d l e ( S T D H a n d l e . S T D _ E R R O R _ H A N D L E ) ;  
 	 	 	 F i l e T y p e   f i l e T y p e   =   ( F i l e T y p e ) G e t F i l e T y p e ( h E r r o r ) ;  
 	 	 	 i f   ( ( f i l e T y p e   = =   F i l e T y p e . F I L E _ T Y P E _ C H A R )   | |   ( f i l e T y p e   = =   F i l e T y p e . F I L E _ T Y P E _ U N K N O W N ) )  
 	 	 	 	 r e t u r n   f a l s e ;  
 	 	 	 r e t u r n   t r u e ;  
 	 	 }  
 	 }  
  
  
 	 i n t e r n a l   c l a s s   P S 2 E X E H o s t U I   :   P S H o s t U s e r I n t e r f a c e  
 	 {  
 	 	 p r i v a t e   P S 2 E X E H o s t R a w U I   r a w U I   =   n u l l ;  
  
 	 	 p u b l i c   C o n s o l e C o l o r   E r r o r F o r e g r o u n d C o l o r   =   C o n s o l e C o l o r . R e d ;  
 	 	 p u b l i c   C o n s o l e C o l o r   E r r o r B a c k g r o u n d C o l o r   =   C o n s o l e C o l o r . B l a c k ;  
  
 	 	 p u b l i c   C o n s o l e C o l o r   W a r n i n g F o r e g r o u n d C o l o r   =   C o n s o l e C o l o r . Y e l l o w ;  
 	 	 p u b l i c   C o n s o l e C o l o r   W a r n i n g B a c k g r o u n d C o l o r   =   C o n s o l e C o l o r . B l a c k ;  
  
 	 	 p u b l i c   C o n s o l e C o l o r   D e b u g F o r e g r o u n d C o l o r   =   C o n s o l e C o l o r . Y e l l o w ;  
 	 	 p u b l i c   C o n s o l e C o l o r   D e b u g B a c k g r o u n d C o l o r   =   C o n s o l e C o l o r . B l a c k ;  
  
 	 	 p u b l i c   C o n s o l e C o l o r   V e r b o s e F o r e g r o u n d C o l o r   =   C o n s o l e C o l o r . Y e l l o w ;  
 	 	 p u b l i c   C o n s o l e C o l o r   V e r b o s e B a c k g r o u n d C o l o r   =   C o n s o l e C o l o r . B l a c k ;  
  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 p u b l i c   C o n s o l e C o l o r   P r o g r e s s F o r e g r o u n d C o l o r   =   C o n s o l e C o l o r . Y e l l o w ;  
 " @   }   e l s e   { @ "  
 	 	 p u b l i c   C o n s o l e C o l o r   P r o g r e s s F o r e g r o u n d C o l o r   =   C o n s o l e C o l o r . D a r k C y a n ;  
 " @   } )  
 	 	 p u b l i c   C o n s o l e C o l o r   P r o g r e s s B a c k g r o u n d C o l o r   =   C o n s o l e C o l o r . D a r k C y a n ;  
  
 	 	 p u b l i c   P S 2 E X E H o s t U I ( )   :   b a s e ( )  
 	 	 {  
 	 	 	 r a w U I   =   n e w   P S 2 E X E H o s t R a w U I ( ) ;  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 r a w U I . F o r e g r o u n d C o l o r   =   C o n s o l e . F o r e g r o u n d C o l o r ;  
 	 	 	 r a w U I . B a c k g r o u n d C o l o r   =   C o n s o l e . B a c k g r o u n d C o l o r ;  
 " @   } )  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   D i c t i o n a r y < s t r i n g ,   P S O b j e c t >   P r o m p t ( s t r i n g   c a p t i o n ,   s t r i n g   m e s s a g e ,   S y s t e m . C o l l e c t i o n s . O b j e c t M o d e l . C o l l e c t i o n < F i e l d D e s c r i p t i o n >   d e s c r i p t i o n s )  
 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( c a p t i o n ) )   W r i t e L i n e ( c a p t i o n ) ;  
 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( m e s s a g e ) )   W r i t e L i n e ( m e s s a g e ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 i f   ( ( ! s t r i n g . I s N u l l O r E m p t y ( c a p t i o n ) )   | |   ( ! s t r i n g . I s N u l l O r E m p t y ( m e s s a g e ) ) )  
 	 	 	 {   s t r i n g   s T i t e l   =   S y s t e m . A p p D o m a i n . C u r r e n t D o m a i n . F r i e n d l y N a m e ,   s M e l d u n g   =   " " ;  
  
 	 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( c a p t i o n ) )   s T i t e l   =   c a p t i o n ;  
 	 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( m e s s a g e ) )   s M e l d u n g   =   m e s s a g e ;  
 	 	 	 	 M e s s a g e B o x . S h o w ( s M e l d u n g ,   s T i t e l ) ;  
 	 	 	 }  
  
 	 	 	 / /   T i t e l   u n d   L a b e l t e x t   f � r   I n p u t b o x   z u r � c k s e t z e n  
 	 	 	 i b c a p t i o n   =   " " ;  
 	 	 	 i b m e s s a g e   =   " " ;  
 " @   } )  
 	 	 	 D i c t i o n a r y < s t r i n g ,   P S O b j e c t >   r e t   =   n e w   D i c t i o n a r y < s t r i n g ,   P S O b j e c t > ( ) ;  
 	 	 	 f o r e a c h   ( F i e l d D e s c r i p t i o n   c d   i n   d e s c r i p t i o n s )  
 	 	 	 {  
 	 	 	 	 T y p e   t   =   n u l l ;  
 	 	 	 	 i f   ( s t r i n g . I s N u l l O r E m p t y ( c d . P a r a m e t e r A s s e m b l y F u l l N a m e ) )  
 	 	 	 	 	 t   =   t y p e o f ( s t r i n g ) ;  
 	 	 	 	 e l s e  
 	 	 	 	 	 t   =   T y p e . G e t T y p e ( c d . P a r a m e t e r A s s e m b l y F u l l N a m e ) ;  
  
 	 	 	 	 i f   ( t . I s A r r a y )  
 	 	 	 	 {  
 	 	 	 	 	 T y p e   e l e m e n t T y p e   =   t . G e t E l e m e n t T y p e ( ) ;  
 	 	 	 	 	 T y p e   g e n e r i c L i s t T y p e   =   T y p e . G e t T y p e ( " S y s t e m . C o l l e c t i o n s . G e n e r i c . L i s t " + ( ( c h a r ) 0 x 6 0 ) . T o S t r i n g ( ) + " 1 " ) ;  
 	 	 	 	 	 g e n e r i c L i s t T y p e   =   g e n e r i c L i s t T y p e . M a k e G e n e r i c T y p e ( n e w   T y p e [ ]   {   e l e m e n t T y p e   } ) ;  
 	 	 	 	 	 C o n s t r u c t o r I n f o   c o n s t r u c t o r   =   g e n e r i c L i s t T y p e . G e t C o n s t r u c t o r ( B i n d i n g F l a g s . C r e a t e I n s t a n c e   |   B i n d i n g F l a g s . I n s t a n c e   |   B i n d i n g F l a g s . P u b l i c ,   n u l l ,   T y p e . E m p t y T y p e s ,   n u l l ) ;  
 	 	 	 	 	 o b j e c t   r e s u l t L i s t   =   c o n s t r u c t o r . I n v o k e ( n u l l ) ;  
  
 	 	 	 	 	 i n t   i n d e x   =   0 ;  
 	 	 	 	 	 s t r i n g   d a t a   =   " " ;  
 	 	 	 	 	 d o  
 	 	 	 	 	 {  
 	 	 	 	 	 	 t r y  
 	 	 	 	 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 	 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( c d . N a m e ) )   W r i t e ( s t r i n g . F o r m a t ( " { 0 } [ { 1 } ] :   " ,   c d . N a m e ,   i n d e x ) ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 	 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( c d . N a m e ) )   i b m e s s a g e   =   s t r i n g . F o r m a t ( " { 0 } [ { 1 } ] :   " ,   c d . N a m e ,   i n d e x ) ;  
 " @   } )  
 	 	 	 	 	 	 	 d a t a   =   R e a d L i n e ( ) ;  
 	 	 	 	 	 	 	 i f   ( s t r i n g . I s N u l l O r E m p t y ( d a t a ) )  
 	 	 	 	 	 	 	 	 b r e a k ;  
  
 	 	 	 	 	 	 	 o b j e c t   o   =   S y s t e m . C o n v e r t . C h a n g e T y p e ( d a t a ,   e l e m e n t T y p e ) ;  
 	 	 	 	 	 	 	 g e n e r i c L i s t T y p e . I n v o k e M e m b e r ( " A d d " ,   B i n d i n g F l a g s . I n v o k e M e t h o d   |   B i n d i n g F l a g s . P u b l i c   |   B i n d i n g F l a g s . I n s t a n c e ,   n u l l ,   r e s u l t L i s t ,   n e w   o b j e c t [ ]   {   o   } ) ;  
 	 	 	 	 	 	 }  
 	 	 	 	 	 	 c a t c h   ( E x c e p t i o n   e )  
 	 	 	 	 	 	 {  
 	 	 	 	 	 	 	 t h r o w   e ;  
 	 	 	 	 	 	 }  
 	 	 	 	 	 	 i n d e x + + ;  
 	 	 	 	 	 }   w h i l e   ( t r u e ) ;  
  
 	 	 	 	 	 S y s t e m . A r r a y   r e t A r r a y   =   ( S y s t e m . A r r a y   ) g e n e r i c L i s t T y p e . I n v o k e M e m b e r ( " T o A r r a y " ,   B i n d i n g F l a g s . I n v o k e M e t h o d   |   B i n d i n g F l a g s . P u b l i c   |   B i n d i n g F l a g s . I n s t a n c e ,   n u l l ,   r e s u l t L i s t ,   n u l l ) ;  
 	 	 	 	 	 r e t . A d d ( c d . N a m e ,   n e w   P S O b j e c t ( r e t A r r a y ) ) ;  
 	 	 	 	 }  
 	 	 	 	 e l s e  
 	 	 	 	 {  
 	 	 	 	 	 o b j e c t   o   =   n u l l ;  
 	 	 	 	 	 s t r i n g   l   =   n u l l ;  
 	 	 	 	 	 t r y  
 	 	 	 	 	 {  
 	 	 	 	 	 	 i f   ( t   ! =   t y p e o f ( S y s t e m . S e c u r i t y . S e c u r e S t r i n g ) )  
 	 	 	 	 	 	 {  
 	 	 	 	 	 	 	 i f   ( t   ! =   t y p e o f ( S y s t e m . M a n a g e m e n t . A u t o m a t i o n . P S C r e d e n t i a l ) )  
 	 	 	 	 	 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 	 	 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( c d . N a m e ) )   W r i t e ( c d . N a m e ) ;  
 	 	 	 	 	 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( c d . H e l p M e s s a g e ) )   W r i t e ( "   ( T y p e   ! ?   f o r   h e l p . ) " ) ;  
 	 	 	 	 	 	 	 	 i f   ( ( ! s t r i n g . I s N u l l O r E m p t y ( c d . N a m e ) )   | |   ( ! s t r i n g . I s N u l l O r E m p t y ( c d . H e l p M e s s a g e ) ) )   W r i t e ( " :   " ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 	 	 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( c d . N a m e ) )   i b m e s s a g e   =   s t r i n g . F o r m a t ( " { 0 } :   " ,   c d . N a m e ) ;  
 	 	 	 	 	 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( c d . H e l p M e s s a g e ) )   i b m e s s a g e   + =   " \ n ( T y p e   ! ?   f o r   h e l p . ) " ;  
 " @   } )  
 	 	 	 	 	 	 	 	 d o   {  
 	 	 	 	 	 	 	 	 	 l   =   R e a d L i n e ( ) ;  
 	 	 	 	 	 	 	 	 	 i f   ( l   = =   " ! ? " )  
 	 	 	 	 	 	 	 	 	 	 W r i t e L i n e ( c d . H e l p M e s s a g e ) ;  
 	 	 	 	 	 	 	 	 	 e l s e  
 	 	 	 	 	 	 	 	 	 {  
 	 	 	 	 	 	 	 	 	 	 i f   ( s t r i n g . I s N u l l O r E m p t y ( l ) )   o   =   c d . D e f a u l t V a l u e ;  
 	 	 	 	 	 	 	 	 	 	 i f   ( o   = =   n u l l )  
 	 	 	 	 	 	 	 	 	 	 {  
 	 	 	 	 	 	 	 	 	 	 	 t r y   {  
 	 	 	 	 	 	 	 	 	 	 	 	 o   =   S y s t e m . C o n v e r t . C h a n g e T y p e ( l ,   t ) ;  
 	 	 	 	 	 	 	 	 	 	 	 }  
 	 	 	 	 	 	 	 	 	 	 	 c a t c h   {  
 	 	 	 	 	 	 	 	 	 	 	 	 W r i t e ( " W r o n g   f o r m a t ,   p l e a s e   r e p e a t   i n p u t :   " ) ;  
 	 	 	 	 	 	 	 	 	 	 	 	 l   =   " ! ? " ;  
 	 	 	 	 	 	 	 	 	 	 	 }  
 	 	 	 	 	 	 	 	 	 	 }  
 	 	 	 	 	 	 	 	 	 }  
 	 	 	 	 	 	 	 	 }   w h i l e   ( l   = =   " ! ? " ) ;  
 	 	 	 	 	 	 	 }  
 	 	 	 	 	 	 	 e l s e  
 	 	 	 	 	 	 	 {  
 	 	 	 	 	 	 	 	 P S C r e d e n t i a l   p s c r e d   =   P r o m p t F o r C r e d e n t i a l ( " " ,   " " ,   " " ,   " " ) ;  
 	 	 	 	 	 	 	 	 o   =   p s c r e d ;  
 	 	 	 	 	 	 	 }  
 	 	 	 	 	 	 }  
 	 	 	 	 	 	 e l s e  
 	 	 	 	 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 	 	 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( c d . N a m e ) )   W r i t e ( s t r i n g . F o r m a t ( " { 0 } :   " ,   c d . N a m e ) ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 	 	 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( c d . N a m e ) )   i b m e s s a g e   =   s t r i n g . F o r m a t ( " { 0 } :   " ,   c d . N a m e ) ;  
 " @   } )  
  
 	 	 	 	 	 	 	 S e c u r e S t r i n g   p w d   =   n u l l ;  
 	 	 	 	 	 	 	 p w d   =   R e a d L i n e A s S e c u r e S t r i n g ( ) ;  
 	 	 	 	 	 	 	 o   =   p w d ;  
 	 	 	 	 	 	 }  
  
 	 	 	 	 	 	 r e t . A d d ( c d . N a m e ,   n e w   P S O b j e c t ( o ) ) ;  
 	 	 	 	 	 }  
 	 	 	 	 	 c a t c h   ( E x c e p t i o n   e )  
 	 	 	 	 	 {  
 	 	 	 	 	 	 t h r o w   e ;  
 	 	 	 	 	 }  
 	 	 	 	 }  
 	 	 	 }  
 $ ( i f   ( $ n o C o n s o l e )   { @ "  
 	 	 	 / /   T i t e l   u n d   L a b e l t e x t   f � r   I n p u t b o x   z u r � c k s e t z e n  
 	 	 	 i b c a p t i o n   =   " " ;  
 	 	 	 i b m e s s a g e   =   " " ;  
 " @   } )  
 	 	 	 r e t u r n   r e t ;  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   i n t   P r o m p t F o r C h o i c e ( s t r i n g   c a p t i o n ,   s t r i n g   m e s s a g e ,   S y s t e m . C o l l e c t i o n s . O b j e c t M o d e l . C o l l e c t i o n < C h o i c e D e s c r i p t i o n >   c h o i c e s ,   i n t   d e f a u l t C h o i c e )  
 	 	 {  
 $ ( i f   ( $ n o C o n s o l e )   { @ "  
 	 	 	 i n t   i R e t u r n   =   C h o i c e B o x . S h o w ( c h o i c e s ,   d e f a u l t C h o i c e ,   c a p t i o n ,   m e s s a g e ) ;  
 	 	 	 i f   ( i R e t u r n   = =   - 1 )   {   i R e t u r n   =   d e f a u l t C h o i c e ;   }  
 	 	 	 r e t u r n   i R e t u r n ;  
 " @   }   e l s e   { @ "  
 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( c a p t i o n ) )  
 	 	 	 	 W r i t e L i n e ( c a p t i o n ) ;  
 	 	 	 W r i t e L i n e ( m e s s a g e ) ;  
 	 	 	 i n t   i d x   =   0 ;  
 	 	 	 S o r t e d L i s t < s t r i n g ,   i n t >   r e s   =   n e w   S o r t e d L i s t < s t r i n g ,   i n t > ( ) ;  
 	 	 	 f o r e a c h   ( C h o i c e D e s c r i p t i o n   c d   i n   c h o i c e s )  
 	 	 	 {  
 	 	 	 	 s t r i n g   l k e y   =   c d . L a b e l . S u b s t r i n g ( 0 ,   1 ) ,   l t e x t   =   c d . L a b e l ;  
 	 	 	 	 i n t   p o s   =   c d . L a b e l . I n d e x O f ( ' & ' ) ;  
 	 	 	 	 i f   ( p o s   >   - 1 )  
 	 	 	 	 {  
 	 	 	 	 	 l k e y   =   c d . L a b e l . S u b s t r i n g ( p o s   +   1 ,   1 ) . T o U p p e r ( ) ;  
 	 	 	 	 	 i f   ( p o s   >   0 )  
 	 	 	 	 	 	 l t e x t   =   c d . L a b e l . S u b s t r i n g ( 0 ,   p o s )   +   c d . L a b e l . S u b s t r i n g ( p o s   +   1 ) ;  
 	 	 	 	 	 e l s e  
 	 	 	 	 	 	 l t e x t   =   c d . L a b e l . S u b s t r i n g ( 1 ) ;  
 	 	 	 	 }  
 	 	 	 	 r e s . A d d ( l k e y . T o L o w e r ( ) ,   i d x ) ;  
  
 	 	 	 	 i f   ( i d x   >   0 )   W r i t e ( "     " ) ;  
 	 	 	 	 i f   ( i d x   = =   d e f a u l t C h o i c e )  
 	 	 	 	 {  
 	 	 	 	 	 W r i t e ( C o n s o l e C o l o r . Y e l l o w ,   C o n s o l e . B a c k g r o u n d C o l o r ,   s t r i n g . F o r m a t ( " [ { 0 } ]   { 1 } " ,   l k e y ,   l t e x t ) ) ;  
 	 	 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( c d . H e l p M e s s a g e ) )  
 	 	 	 	 	 	 W r i t e ( C o n s o l e C o l o r . G r a y ,   C o n s o l e . B a c k g r o u n d C o l o r ,   s t r i n g . F o r m a t ( "   ( { 0 } ) " ,   c d . H e l p M e s s a g e ) ) ;  
 	 	 	 	 }  
 	 	 	 	 e l s e  
 	 	 	 	 {  
 	 	 	 	 	 W r i t e ( C o n s o l e C o l o r . G r a y ,   C o n s o l e . B a c k g r o u n d C o l o r ,   s t r i n g . F o r m a t ( " [ { 0 } ]   { 1 } " ,   l k e y ,   l t e x t ) ) ;  
 	 	 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( c d . H e l p M e s s a g e ) )  
 	 	 	 	 	 	 W r i t e ( C o n s o l e C o l o r . G r a y ,   C o n s o l e . B a c k g r o u n d C o l o r ,   s t r i n g . F o r m a t ( "   ( { 0 } ) " ,   c d . H e l p M e s s a g e ) ) ;  
 	 	 	 	 }  
 	 	 	 	 i d x + + ;  
 	 	 	 }  
 	 	 	 W r i t e ( " :   " ) ;  
  
 	 	 	 t r y  
 	 	 	 {  
 	 	 	 	 w h i l e   ( t r u e )  
 	 	 	 	 {   s t r i n g   s   =   C o n s o l e . R e a d L i n e ( ) . T o L o w e r ( ) ;  
 	 	 	 	 	 i f   ( r e s . C o n t a i n s K e y ( s ) )  
 	 	 	 	 	 	 r e t u r n   r e s [ s ] ;  
 	 	 	 	 	 i f   ( s t r i n g . I s N u l l O r E m p t y ( s ) )  
 	 	 	 	 	 	 r e t u r n   d e f a u l t C h o i c e ;  
 	 	 	 	 }  
 	 	 	 }  
 	 	 	 c a t c h   {   }  
  
 	 	 	 r e t u r n   d e f a u l t C h o i c e ;  
 " @   } )  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   P S C r e d e n t i a l   P r o m p t F o r C r e d e n t i a l ( s t r i n g   c a p t i o n ,   s t r i n g   m e s s a g e ,   s t r i n g   u s e r N a m e ,   s t r i n g   t a r g e t N a m e ,   P S C r e d e n t i a l T y p e s   a l l o w e d C r e d e n t i a l T y p e s ,   P S C r e d e n t i a l U I O p t i o n s   o p t i o n s )  
 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e   - a n d   ! $ c r e d e n t i a l G U I )   { @ "  
 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( c a p t i o n ) )   W r i t e L i n e ( c a p t i o n ) ;  
 	 	 	 W r i t e L i n e ( m e s s a g e ) ;  
  
 	 	 	 s t r i n g   u n ;  
 	 	 	 i f   ( ( s t r i n g . I s N u l l O r E m p t y ( u s e r N a m e ) )   | |   ( ( o p t i o n s   &   P S C r e d e n t i a l U I O p t i o n s . R e a d O n l y U s e r N a m e )   = =   0 ) )  
 	 	 	 {  
 	 	 	 	 W r i t e ( " U s e r   n a m e :   " ) ;  
 	 	 	 	 u n   =   R e a d L i n e ( ) ;  
 	 	 	 }  
 	 	 	 e l s e  
 	 	 	 {  
 	 	 	 	 W r i t e ( " U s e r   n a m e :   " ) ;  
 	 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( t a r g e t N a m e ) )   W r i t e ( t a r g e t N a m e   +   " \ \ " ) ;  
 	 	 	 	 W r i t e L i n e ( u s e r N a m e ) ;  
 	 	 	 	 u n   =   u s e r N a m e ;  
 	 	 	 }  
 	 	 	 S e c u r e S t r i n g   p w d   =   n u l l ;  
 	 	 	 W r i t e ( " P a s s w o r d :   " ) ;  
 	 	 	 p w d   =   R e a d L i n e A s S e c u r e S t r i n g ( ) ;  
  
 	 	 	 i f   ( s t r i n g . I s N u l l O r E m p t y ( u n ) )   u n   =   " < N O U S E R > " ;  
 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( t a r g e t N a m e ) )  
 	 	 	 {  
 	 	 	 	 i f   ( u n . I n d e x O f ( ' \ \ ' )   <   0 )  
 	 	 	 	 	 u n   =   t a r g e t N a m e   +   " \ \ "   +   u n ;  
 	 	 	 }  
  
 	 	 	 P S C r e d e n t i a l   c 2   =   n e w   P S C r e d e n t i a l ( u n ,   p w d ) ;  
 	 	 	 r e t u r n   c 2 ;  
 " @   }   e l s e   { @ "  
 	 	 	 i k . P o w e r S h e l l . C r e d e n t i a l F o r m . U s e r P w d   c r e d   =   C r e d e n t i a l F o r m . P r o m p t F o r P a s s w o r d ( c a p t i o n ,   m e s s a g e ,   t a r g e t N a m e ,   u s e r N a m e ,   a l l o w e d C r e d e n t i a l T y p e s ,   o p t i o n s ) ;  
 	 	 	 i f   ( c r e d   ! =   n u l l )  
 	 	 	 {  
 	 	 	 	 S y s t e m . S e c u r i t y . S e c u r e S t r i n g   x   =   n e w   S y s t e m . S e c u r i t y . S e c u r e S t r i n g ( ) ;  
 	 	 	 	 f o r e a c h   ( c h a r   c   i n   c r e d . P a s s w o r d . T o C h a r A r r a y ( ) )  
 	 	 	 	 	 x . A p p e n d C h a r ( c ) ;  
  
 	 	 	 	 r e t u r n   n e w   P S C r e d e n t i a l ( c r e d . U s e r ,   x ) ;  
 	 	 	 }  
 	 	 	 r e t u r n   n u l l ;  
 " @   } )  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   P S C r e d e n t i a l   P r o m p t F o r C r e d e n t i a l ( s t r i n g   c a p t i o n ,   s t r i n g   m e s s a g e ,   s t r i n g   u s e r N a m e ,   s t r i n g   t a r g e t N a m e )  
 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e   - a n d   ! $ c r e d e n t i a l G U I )   { @ "  
 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( c a p t i o n ) )   W r i t e L i n e ( c a p t i o n ) ;  
 	 	 	 W r i t e L i n e ( m e s s a g e ) ;  
  
 	 	 	 s t r i n g   u n ;  
 	 	 	 i f   ( s t r i n g . I s N u l l O r E m p t y ( u s e r N a m e ) )  
 	 	 	 {  
 	 	 	 	 W r i t e ( " U s e r   n a m e :   " ) ;  
 	 	 	 	 u n   =   R e a d L i n e ( ) ;  
 	 	 	 }  
 	 	 	 e l s e  
 	 	 	 {  
 	 	 	 	 W r i t e ( " U s e r   n a m e :   " ) ;  
 	 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( t a r g e t N a m e ) )   W r i t e ( t a r g e t N a m e   +   " \ \ " ) ;  
 	 	 	 	 W r i t e L i n e ( u s e r N a m e ) ;  
 	 	 	 	 u n   =   u s e r N a m e ;  
 	 	 	 }  
 	 	 	 S e c u r e S t r i n g   p w d   =   n u l l ;  
 	 	 	 W r i t e ( " P a s s w o r d :   " ) ;  
 	 	 	 p w d   =   R e a d L i n e A s S e c u r e S t r i n g ( ) ;  
  
 	 	 	 i f   ( s t r i n g . I s N u l l O r E m p t y ( u n ) )   u n   =   " < N O U S E R > " ;  
 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( t a r g e t N a m e ) )  
 	 	 	 {  
 	 	 	 	 i f   ( u n . I n d e x O f ( ' \ \ ' )   <   0 )  
 	 	 	 	 	 u n   =   t a r g e t N a m e   +   " \ \ "   +   u n ;  
 	 	 	 }  
  
 	 	 	 P S C r e d e n t i a l   c 2   =   n e w   P S C r e d e n t i a l ( u n ,   p w d ) ;  
 	 	 	 r e t u r n   c 2 ;  
 " @   }   e l s e   { @ "  
 	 	 	 i k . P o w e r S h e l l . C r e d e n t i a l F o r m . U s e r P w d   c r e d   =   C r e d e n t i a l F o r m . P r o m p t F o r P a s s w o r d ( c a p t i o n ,   m e s s a g e ,   t a r g e t N a m e ,   u s e r N a m e ,   P S C r e d e n t i a l T y p e s . D e f a u l t ,   P S C r e d e n t i a l U I O p t i o n s . D e f a u l t ) ;  
 	 	 	 i f   ( c r e d   ! =   n u l l )  
 	 	 	 {  
 	 	 	 	 S y s t e m . S e c u r i t y . S e c u r e S t r i n g   x   =   n e w   S y s t e m . S e c u r i t y . S e c u r e S t r i n g ( ) ;  
 	 	 	 	 f o r e a c h   ( c h a r   c   i n   c r e d . P a s s w o r d . T o C h a r A r r a y ( ) )  
 	 	 	 	 	 x . A p p e n d C h a r ( c ) ;  
  
 	 	 	 	 r e t u r n   n e w   P S C r e d e n t i a l ( c r e d . U s e r ,   x ) ;  
 	 	 	 }  
 	 	 	 r e t u r n   n u l l ;  
 " @   } )  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   P S H o s t R a w U s e r I n t e r f a c e   R a w U I  
 	 	 {  
 	 	 	 g e t  
 	 	 	 {  
 	 	 	 	 r e t u r n   r a w U I ;  
 	 	 	 }  
 	 	 }  
  
 $ ( i f   ( $ n o C o n s o l e )   { @ "  
 	 	 p r i v a t e   s t r i n g   i b c a p t i o n ;  
 	 	 p r i v a t e   s t r i n g   i b m e s s a g e ;  
 " @   } )  
  
 	 	 p u b l i c   o v e r r i d e   s t r i n g   R e a d L i n e ( )  
 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 r e t u r n   C o n s o l e . R e a d L i n e ( ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 s t r i n g   s W e r t   =   " " ;  
 	 	 	 i f   ( I n p u t B o x . S h o w ( i b c a p t i o n ,   i b m e s s a g e ,   r e f   s W e r t )   = =   D i a l o g R e s u l t . O K )  
 	 	 	 	 r e t u r n   s W e r t ;  
 	 	 	 e l s e  
 	 	 	 	 r e t u r n   " " ;  
 " @   } )  
 	 	 }  
  
 	 	 p r i v a t e   S y s t e m . S e c u r i t y . S e c u r e S t r i n g   g e t P a s s w o r d ( )  
 	 	 {  
 	 	 	 S y s t e m . S e c u r i t y . S e c u r e S t r i n g   p w d   =   n e w   S y s t e m . S e c u r i t y . S e c u r e S t r i n g ( ) ;  
 	 	 	 w h i l e   ( t r u e )  
 	 	 	 {  
 	 	 	 	 C o n s o l e K e y I n f o   i   =   C o n s o l e . R e a d K e y ( t r u e ) ;  
 	 	 	 	 i f   ( i . K e y   = =   C o n s o l e K e y . E n t e r )  
 	 	 	 	 {  
 	 	 	 	 	 C o n s o l e . W r i t e L i n e ( ) ;  
 	 	 	 	 	 b r e a k ;  
 	 	 	 	 }  
 	 	 	 	 e l s e   i f   ( i . K e y   = =   C o n s o l e K e y . B a c k s p a c e )  
 	 	 	 	 {  
 	 	 	 	 	 i f   ( p w d . L e n g t h   >   0 )  
 	 	 	 	 	 {  
 	 	 	 	 	 	 p w d . R e m o v e A t ( p w d . L e n g t h   -   1 ) ;  
 	 	 	 	 	 	 C o n s o l e . W r i t e ( " \ b   \ b " ) ;  
 	 	 	 	 	 }  
 	 	 	 	 }  
 	 	 	 	 e l s e  
 	 	 	 	 {  
 	 	 	 	 	 p w d . A p p e n d C h a r ( i . K e y C h a r ) ;  
 	 	 	 	 	 C o n s o l e . W r i t e ( " * " ) ;  
 	 	 	 	 }  
 	 	 	 }  
 	 	 	 r e t u r n   p w d ;  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   S y s t e m . S e c u r i t y . S e c u r e S t r i n g   R e a d L i n e A s S e c u r e S t r i n g ( )  
 	 	 {  
 	 	 	 S y s t e m . S e c u r i t y . S e c u r e S t r i n g   s e c s t r   =   n e w   S y s t e m . S e c u r i t y . S e c u r e S t r i n g ( ) ;  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 s e c s t r   =   g e t P a s s w o r d ( ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 s t r i n g   s W e r t   =   " " ;  
  
 	 	 	 i f   ( I n p u t B o x . S h o w ( i b c a p t i o n ,   i b m e s s a g e ,   r e f   s W e r t ,   t r u e )   = =   D i a l o g R e s u l t . O K )  
 	 	 	 {  
 	 	 	 	 f o r e a c h   ( c h a r   c h   i n   s W e r t )  
 	 	 	 	 	 s e c s t r . A p p e n d C h a r ( c h ) ;  
 	 	 	 }  
 " @   } )  
 	 	 	 r e t u r n   s e c s t r ;  
 	 	 }  
  
 	 	 / /   c a l l e d   b y   W r i t e - H o s t  
 	 	 p u b l i c   o v e r r i d e   v o i d   W r i t e ( C o n s o l e C o l o r   f o r e g r o u n d C o l o r ,   C o n s o l e C o l o r   b a c k g r o u n d C o l o r ,   s t r i n g   v a l u e )  
 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 C o n s o l e C o l o r   f g c   =   C o n s o l e . F o r e g r o u n d C o l o r ,   b g c   =   C o n s o l e . B a c k g r o u n d C o l o r ;  
 	 	 	 C o n s o l e . F o r e g r o u n d C o l o r   =   f o r e g r o u n d C o l o r ;  
 	 	 	 C o n s o l e . B a c k g r o u n d C o l o r   =   b a c k g r o u n d C o l o r ;  
 	 	 	 C o n s o l e . W r i t e ( v a l u e ) ;  
 	 	 	 C o n s o l e . F o r e g r o u n d C o l o r   =   f g c ;  
 	 	 	 C o n s o l e . B a c k g r o u n d C o l o r   =   b g c ;  
 " @   }   e l s e   { @ "  
 	 	 	 i f   ( ( ! s t r i n g . I s N u l l O r E m p t y ( v a l u e ) )   & &   ( v a l u e   ! =   " \ n " ) )  
 	 	 	 	 M e s s a g e B o x . S h o w ( v a l u e ,   S y s t e m . A p p D o m a i n . C u r r e n t D o m a i n . F r i e n d l y N a m e ) ;  
 " @   } )  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   v o i d   W r i t e ( s t r i n g   v a l u e )  
 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 C o n s o l e . W r i t e ( v a l u e ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 i f   ( ( ! s t r i n g . I s N u l l O r E m p t y ( v a l u e ) )   & &   ( v a l u e   ! =   " \ n " ) )  
 	 	 	 	 M e s s a g e B o x . S h o w ( v a l u e ,   S y s t e m . A p p D o m a i n . C u r r e n t D o m a i n . F r i e n d l y N a m e ) ;  
 " @   } )  
 	 	 }  
  
 	 	 / /   c a l l e d   b y   W r i t e - D e b u g  
 	 	 p u b l i c   o v e r r i d e   v o i d   W r i t e D e b u g L i n e ( s t r i n g   m e s s a g e )  
 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 W r i t e L i n e ( D e b u g F o r e g r o u n d C o l o r ,   D e b u g B a c k g r o u n d C o l o r ,   s t r i n g . F o r m a t ( " D E B U G :   { 0 } " ,   m e s s a g e ) ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 M e s s a g e B o x . S h o w ( m e s s a g e ,   S y s t e m . A p p D o m a i n . C u r r e n t D o m a i n . F r i e n d l y N a m e ,   M e s s a g e B o x B u t t o n s . O K ,   M e s s a g e B o x I c o n . I n f o r m a t i o n ) ;  
 " @   } )  
 	 	 }  
  
 	 	 / /   c a l l e d   b y   W r i t e - E r r o r  
 	 	 p u b l i c   o v e r r i d e   v o i d   W r i t e E r r o r L i n e ( s t r i n g   v a l u e )  
 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 i f   ( C o n s o l e I n f o . I s E r r o r R e d i r e c t e d ( ) )  
 	 	 	 	 C o n s o l e . E r r o r . W r i t e L i n e ( s t r i n g . F o r m a t ( " E R R O R :   { 0 } " ,   v a l u e ) ) ;  
 	 	 	 e l s e  
 	 	 	 	 W r i t e L i n e ( E r r o r F o r e g r o u n d C o l o r ,   E r r o r B a c k g r o u n d C o l o r ,   s t r i n g . F o r m a t ( " E R R O R :   { 0 } " ,   v a l u e ) ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 M e s s a g e B o x . S h o w ( v a l u e ,   S y s t e m . A p p D o m a i n . C u r r e n t D o m a i n . F r i e n d l y N a m e ,   M e s s a g e B o x B u t t o n s . O K ,   M e s s a g e B o x I c o n . E r r o r ) ;  
 " @   } )  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   v o i d   W r i t e L i n e ( )  
 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 C o n s o l e . W r i t e L i n e ( ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 M e s s a g e B o x . S h o w ( " " ,   S y s t e m . A p p D o m a i n . C u r r e n t D o m a i n . F r i e n d l y N a m e ) ;  
 " @   } )  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   v o i d   W r i t e L i n e ( C o n s o l e C o l o r   f o r e g r o u n d C o l o r ,   C o n s o l e C o l o r   b a c k g r o u n d C o l o r ,   s t r i n g   v a l u e )  
 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 C o n s o l e C o l o r   f g c   =   C o n s o l e . F o r e g r o u n d C o l o r ,   b g c   =   C o n s o l e . B a c k g r o u n d C o l o r ;  
 	 	 	 C o n s o l e . F o r e g r o u n d C o l o r   =   f o r e g r o u n d C o l o r ;  
 	 	 	 C o n s o l e . B a c k g r o u n d C o l o r   =   b a c k g r o u n d C o l o r ;  
 	 	 	 C o n s o l e . W r i t e L i n e ( v a l u e ) ;  
 	 	 	 C o n s o l e . F o r e g r o u n d C o l o r   =   f g c ;  
 	 	 	 C o n s o l e . B a c k g r o u n d C o l o r   =   b g c ;  
 " @   }   e l s e   { @ "  
 	 	 	 i f   ( ( ! s t r i n g . I s N u l l O r E m p t y ( v a l u e ) )   & &   ( v a l u e   ! =   " \ n " ) )  
 	 	 	 	 M e s s a g e B o x . S h o w ( v a l u e ,   S y s t e m . A p p D o m a i n . C u r r e n t D o m a i n . F r i e n d l y N a m e ) ;  
 " @   } )  
 	 	 }  
  
 	 	 / /   c a l l e d   b y   W r i t e - O u t p u t  
 	 	 p u b l i c   o v e r r i d e   v o i d   W r i t e L i n e ( s t r i n g   v a l u e )  
 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 C o n s o l e . W r i t e L i n e ( v a l u e ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 i f   ( ( ! s t r i n g . I s N u l l O r E m p t y ( v a l u e ) )   & &   ( v a l u e   ! =   " \ n " ) )  
 	 	 	 	 M e s s a g e B o x . S h o w ( v a l u e ,   S y s t e m . A p p D o m a i n . C u r r e n t D o m a i n . F r i e n d l y N a m e ) ;  
 " @   } )  
 	 	 }  
  
 $ ( i f   ( $ n o C o n s o l e )   { @ "  
 	 	 p u b l i c   P r o g r e s s F o r m   p f   =   n u l l ;  
 " @   } )  
 	 	 p u b l i c   o v e r r i d e   v o i d   W r i t e P r o g r e s s ( l o n g   s o u r c e I d ,   P r o g r e s s R e c o r d   r e c o r d )  
 	 	 {  
 $ ( i f   ( $ n o C o n s o l e )   { @ "  
 	 	 	 i f   ( p f   = =   n u l l )  
 	 	 	 {  
 	 	 	 	 p f   =   n e w   P r o g r e s s F o r m ( P r o g r e s s F o r e g r o u n d C o l o r ) ;  
 	 	 	 	 p f . S h o w ( ) ;  
 	 	 	 }  
 	 	 	 p f . U p d a t e ( r e c o r d ) ;  
 	 	 	 i f   ( r e c o r d . R e c o r d T y p e   = =   P r o g r e s s R e c o r d T y p e . C o m p l e t e d )  
 	 	 	 {  
 	 	 	 	 p f   =   n u l l ;  
 	 	 	 }  
 " @   } )  
 	 	 }  
  
 	 	 / /   c a l l e d   b y   W r i t e - V e r b o s e  
 	 	 p u b l i c   o v e r r i d e   v o i d   W r i t e V e r b o s e L i n e ( s t r i n g   m e s s a g e )  
 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 W r i t e L i n e ( V e r b o s e F o r e g r o u n d C o l o r ,   V e r b o s e B a c k g r o u n d C o l o r ,   s t r i n g . F o r m a t ( " V E R B O S E :   { 0 } " ,   m e s s a g e ) ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 M e s s a g e B o x . S h o w ( m e s s a g e ,   S y s t e m . A p p D o m a i n . C u r r e n t D o m a i n . F r i e n d l y N a m e ,   M e s s a g e B o x B u t t o n s . O K ,   M e s s a g e B o x I c o n . I n f o r m a t i o n ) ;  
 " @   } )  
 	 	 }  
  
 	 	 / /   c a l l e d   b y   W r i t e - W a r n i n g  
 	 	 p u b l i c   o v e r r i d e   v o i d   W r i t e W a r n i n g L i n e ( s t r i n g   m e s s a g e )  
 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 W r i t e L i n e ( W a r n i n g F o r e g r o u n d C o l o r ,   W a r n i n g B a c k g r o u n d C o l o r ,   s t r i n g . F o r m a t ( " W A R N I N G :   { 0 } " ,   m e s s a g e ) ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 M e s s a g e B o x . S h o w ( m e s s a g e ,   S y s t e m . A p p D o m a i n . C u r r e n t D o m a i n . F r i e n d l y N a m e ,   M e s s a g e B o x B u t t o n s . O K ,   M e s s a g e B o x I c o n . W a r n i n g ) ;  
 " @   } )  
 	 	 }  
 	 }  
  
 	 i n t e r n a l   c l a s s   P S 2 E X E H o s t   :   P S H o s t  
 	 {  
 	 	 p r i v a t e   P S 2 E X E A p p   p a r e n t ;  
 	 	 p r i v a t e   P S 2 E X E H o s t U I   u i   =   n u l l ;  
  
 	 	 p r i v a t e   C u l t u r e I n f o   o r i g i n a l C u l t u r e I n f o   =   S y s t e m . T h r e a d i n g . T h r e a d . C u r r e n t T h r e a d . C u r r e n t C u l t u r e ;  
  
 	 	 p r i v a t e   C u l t u r e I n f o   o r i g i n a l U I C u l t u r e I n f o   =   S y s t e m . T h r e a d i n g . T h r e a d . C u r r e n t T h r e a d . C u r r e n t U I C u l t u r e ;  
  
 	 	 p r i v a t e   G u i d   m y I d   =   G u i d . N e w G u i d ( ) ;  
  
 	 	 p u b l i c   P S 2 E X E H o s t ( P S 2 E X E A p p   a p p ,   P S 2 E X E H o s t U I   u i )  
 	 	 {  
 	 	 	 t h i s . p a r e n t   =   a p p ;  
 	 	 	 t h i s . u i   =   u i ;  
 	 	 }  
  
 	 	 p u b l i c   c l a s s   C o n s o l e C o l o r P r o x y  
 	 	 {  
 	 	 	 p r i v a t e   P S 2 E X E H o s t U I   _ u i ;  
  
 	 	 	 p u b l i c   C o n s o l e C o l o r P r o x y ( P S 2 E X E H o s t U I   u i )  
 	 	 	 {  
 	 	 	 	 i f   ( u i   = =   n u l l )   t h r o w   n e w   A r g u m e n t N u l l E x c e p t i o n ( " u i " ) ;  
 	 	 	 	 _ u i   =   u i ;  
 	 	 	 }  
  
 	 	 	 p u b l i c   C o n s o l e C o l o r   E r r o r F o r e g r o u n d C o l o r  
 	 	 	 {  
 	 	 	 	 g e t  
 	 	 	 	 {   r e t u r n   _ u i . E r r o r F o r e g r o u n d C o l o r ;   }  
 	 	 	 	 s e t  
 	 	 	 	 {   _ u i . E r r o r F o r e g r o u n d C o l o r   =   v a l u e ;   }  
 	 	 	 }  
  
 	 	 	 p u b l i c   C o n s o l e C o l o r   E r r o r B a c k g r o u n d C o l o r  
 	 	 	 {  
 	 	 	 	 g e t  
 	 	 	 	 {   r e t u r n   _ u i . E r r o r B a c k g r o u n d C o l o r ;   }  
 	 	 	 	 s e t  
 	 	 	 	 {   _ u i . E r r o r B a c k g r o u n d C o l o r   =   v a l u e ;   }  
 	 	 	 }  
  
 	 	 	 p u b l i c   C o n s o l e C o l o r   W a r n i n g F o r e g r o u n d C o l o r  
 	 	 	 {  
 	 	 	 	 g e t  
 	 	 	 	 {   r e t u r n   _ u i . W a r n i n g F o r e g r o u n d C o l o r ;   }  
 	 	 	 	 s e t  
 	 	 	 	 {   _ u i . W a r n i n g F o r e g r o u n d C o l o r   =   v a l u e ;   }  
 	 	 	 }  
  
 	 	 	 p u b l i c   C o n s o l e C o l o r   W a r n i n g B a c k g r o u n d C o l o r  
 	 	 	 {  
 	 	 	 	 g e t  
 	 	 	 	 {   r e t u r n   _ u i . W a r n i n g B a c k g r o u n d C o l o r ;   }  
 	 	 	 	 s e t  
 	 	 	 	 {   _ u i . W a r n i n g B a c k g r o u n d C o l o r   =   v a l u e ;   }  
 	 	 	 }  
  
 	 	 	 p u b l i c   C o n s o l e C o l o r   D e b u g F o r e g r o u n d C o l o r  
 	 	 	 {  
 	 	 	 	 g e t  
 	 	 	 	 {   r e t u r n   _ u i . D e b u g F o r e g r o u n d C o l o r ;   }  
 	 	 	 	 s e t  
 	 	 	 	 {   _ u i . D e b u g F o r e g r o u n d C o l o r   =   v a l u e ;   }  
 	 	 	 }  
  
 	 	 	 p u b l i c   C o n s o l e C o l o r   D e b u g B a c k g r o u n d C o l o r  
 	 	 	 {  
 	 	 	 	 g e t  
 	 	 	 	 {   r e t u r n   _ u i . D e b u g B a c k g r o u n d C o l o r ;   }  
 	 	 	 	 s e t  
 	 	 	 	 {   _ u i . D e b u g B a c k g r o u n d C o l o r   =   v a l u e ;   }  
 	 	 	 }  
  
 	 	 	 p u b l i c   C o n s o l e C o l o r   V e r b o s e F o r e g r o u n d C o l o r  
 	 	 	 {  
 	 	 	 	 g e t  
 	 	 	 	 {   r e t u r n   _ u i . V e r b o s e F o r e g r o u n d C o l o r ;   }  
 	 	 	 	 s e t  
 	 	 	 	 {   _ u i . V e r b o s e F o r e g r o u n d C o l o r   =   v a l u e ;   }  
 	 	 	 }  
  
 	 	 	 p u b l i c   C o n s o l e C o l o r   V e r b o s e B a c k g r o u n d C o l o r  
 	 	 	 {  
 	 	 	 	 g e t  
 	 	 	 	 {   r e t u r n   _ u i . V e r b o s e B a c k g r o u n d C o l o r ;   }  
 	 	 	 	 s e t  
 	 	 	 	 {   _ u i . V e r b o s e B a c k g r o u n d C o l o r   =   v a l u e ;   }  
 	 	 	 }  
  
 	 	 	 p u b l i c   C o n s o l e C o l o r   P r o g r e s s F o r e g r o u n d C o l o r  
 	 	 	 {  
 	 	 	 	 g e t  
 	 	 	 	 {   r e t u r n   _ u i . P r o g r e s s F o r e g r o u n d C o l o r ;   }  
 	 	 	 	 s e t  
 	 	 	 	 {   _ u i . P r o g r e s s F o r e g r o u n d C o l o r   =   v a l u e ;   }  
 	 	 	 }  
  
 	 	 	 p u b l i c   C o n s o l e C o l o r   P r o g r e s s B a c k g r o u n d C o l o r  
 	 	 	 {  
 	 	 	 	 g e t  
 	 	 	 	 {   r e t u r n   _ u i . P r o g r e s s B a c k g r o u n d C o l o r ;   }  
 	 	 	 	 s e t  
 	 	 	 	 {   _ u i . P r o g r e s s B a c k g r o u n d C o l o r   =   v a l u e ;   }  
 	 	 	 }  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   P S O b j e c t   P r i v a t e D a t a  
 	 	 {  
 	 	 	 g e t  
 	 	 	 {  
 	 	 	 	 i f   ( u i   = =   n u l l )   r e t u r n   n u l l ;  
 	 	 	 	 r e t u r n   _ c o n s o l e C o l o r P r o x y   ? ?   ( _ c o n s o l e C o l o r P r o x y   =   P S O b j e c t . A s P S O b j e c t ( n e w   C o n s o l e C o l o r P r o x y ( u i ) ) ) ;  
 	 	 	 }  
 	 	 }  
  
 	 	 p r i v a t e   P S O b j e c t   _ c o n s o l e C o l o r P r o x y ;  
  
 	 	 p u b l i c   o v e r r i d e   S y s t e m . G l o b a l i z a t i o n . C u l t u r e I n f o   C u r r e n t C u l t u r e  
 	 	 {  
 	 	 	 g e t  
 	 	 	 {  
 	 	 	 	 r e t u r n   t h i s . o r i g i n a l C u l t u r e I n f o ;  
 	 	 	 }  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   S y s t e m . G l o b a l i z a t i o n . C u l t u r e I n f o   C u r r e n t U I C u l t u r e  
 	 	 {  
 	 	 	 g e t  
 	 	 	 {  
 	 	 	 	 r e t u r n   t h i s . o r i g i n a l U I C u l t u r e I n f o ;  
 	 	 	 }  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   G u i d   I n s t a n c e I d  
 	 	 {  
 	 	 	 g e t  
 	 	 	 {  
 	 	 	 	 r e t u r n   t h i s . m y I d ;  
 	 	 	 }  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   s t r i n g   N a m e  
 	 	 {  
 	 	 	 g e t  
 	 	 	 {  
 	 	 	 	 r e t u r n   " P S 2 E X E _ H o s t " ;  
 	 	 	 }  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   P S H o s t U s e r I n t e r f a c e   U I  
 	 	 {  
 	 	 	 g e t  
 	 	 	 {  
 	 	 	 	 r e t u r n   u i ;  
 	 	 	 }  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   V e r s i o n   V e r s i o n  
 	 	 {  
 	 	 	 g e t  
 	 	 	 {  
 	 	 	 	 r e t u r n   n e w   V e r s i o n ( 0 ,   5 ,   0 ,   1 3 ) ;  
 	 	 	 }  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   v o i d   E n t e r N e s t e d P r o m p t ( )  
 	 	 {  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   v o i d   E x i t N e s t e d P r o m p t ( )  
 	 	 {  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   v o i d   N o t i f y B e g i n A p p l i c a t i o n ( )  
 	 	 {  
 	 	 	 r e t u r n ;  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   v o i d   N o t i f y E n d A p p l i c a t i o n ( )  
 	 	 {  
 	 	 	 r e t u r n ;  
 	 	 }  
  
 	 	 p u b l i c   o v e r r i d e   v o i d   S e t S h o u l d E x i t ( i n t   e x i t C o d e )  
 	 	 {  
 	 	 	 t h i s . p a r e n t . S h o u l d E x i t   =   t r u e ;  
 	 	 	 t h i s . p a r e n t . E x i t C o d e   =   e x i t C o d e ;  
 	 	 }  
 	 }  
  
 	 i n t e r n a l   i n t e r f a c e   P S 2 E X E A p p  
 	 {  
 	 	 b o o l   S h o u l d E x i t   {   g e t ;   s e t ;   }  
 	 	 i n t   E x i t C o d e   {   g e t ;   s e t ;   }  
 	 }  
  
 	 i n t e r n a l   c l a s s   P S 2 E X E   :   P S 2 E X E A p p  
 	 {  
 	 	 p r i v a t e   b o o l   s h o u l d E x i t ;  
  
 	 	 p r i v a t e   i n t   e x i t C o d e ;  
  
 	 	 p u b l i c   b o o l   S h o u l d E x i t  
 	 	 {  
 	 	 	 g e t   {   r e t u r n   t h i s . s h o u l d E x i t ;   }  
 	 	 	 s e t   {   t h i s . s h o u l d E x i t   =   v a l u e ;   }  
 	 	 }  
  
 	 	 p u b l i c   i n t   E x i t C o d e  
 	 	 {  
 	 	 	 g e t   {   r e t u r n   t h i s . e x i t C o d e ;   }  
 	 	 	 s e t   {   t h i s . e x i t C o d e   =   v a l u e ;   }  
 	 	 }  
  
 	 	 $ ( i f   ( $ S t a ) { " [ S T A T h r e a d ] " } ) $ ( i f   ( $ M t a ) { " [ M T A T h r e a d ] " } )  
 	 	 p r i v a t e   s t a t i c   i n t   M a i n ( s t r i n g [ ]   a r g s )  
 	 	 {  
 	 	 	 $ c u l t u r e  
  
 	 	 	 P S 2 E X E   m e   =   n e w   P S 2 E X E ( ) ;  
  
 	 	 	 b o o l   p a r a m W a i t   =   f a l s e ;  
 	 	 	 s t r i n g   e x t r a c t F N   =   s t r i n g . E m p t y ;  
  
 	 	 	 P S 2 E X E H o s t U I   u i   =   n e w   P S 2 E X E H o s t U I ( ) ;  
 	 	 	 P S 2 E X E H o s t   h o s t   =   n e w   P S 2 E X E H o s t ( m e ,   u i ) ;  
 	 	 	 S y s t e m . T h r e a d i n g . M a n u a l R e s e t E v e n t   m r e   =   n e w   S y s t e m . T h r e a d i n g . M a n u a l R e s e t E v e n t ( f a l s e ) ;  
  
 	 	 	 A p p D o m a i n . C u r r e n t D o m a i n . U n h a n d l e d E x c e p t i o n   + =   n e w   U n h a n d l e d E x c e p t i o n E v e n t H a n d l e r ( C u r r e n t D o m a i n _ U n h a n d l e d E x c e p t i o n ) ;  
  
 	 	 	 t r y  
 	 	 	 {  
 	 	 	 	 u s i n g   ( R u n s p a c e   m y R u n S p a c e   =   R u n s p a c e F a c t o r y . C r e a t e R u n s p a c e ( h o s t ) )  
 	 	 	 	 {  
 	 	 	 	 	 $ ( i f   ( $ S t a   - o r   $ M t a )   { " m y R u n S p a c e . A p a r t m e n t S t a t e   =   S y s t e m . T h r e a d i n g . A p a r t m e n t S t a t e . " } ) $ ( i f   ( $ S t a ) { " S T A " } ) $ ( i f   ( $ M t a ) { " M T A " } ) ;  
 	 	 	 	 	 m y R u n S p a c e . O p e n ( ) ;  
  
 	 	 	 	 	 u s i n g   ( S y s t e m . M a n a g e m e n t . A u t o m a t i o n . P o w e r S h e l l   p o w e r s h e l l   =   S y s t e m . M a n a g e m e n t . A u t o m a t i o n . P o w e r S h e l l . C r e a t e ( ) )  
 	 	 	 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 	 	 	 C o n s o l e . C a n c e l K e y P r e s s   + =   n e w   C o n s o l e C a n c e l E v e n t H a n d l e r ( d e l e g a t e ( o b j e c t   s e n d e r ,   C o n s o l e C a n c e l E v e n t A r g s   e )  
 	 	 	 	 	 	 {  
 	 	 	 	 	 	 	 t r y  
 	 	 	 	 	 	 	 {  
 	 	 	 	 	 	 	 	 p o w e r s h e l l . B e g i n S t o p ( n e w   A s y n c C a l l b a c k ( d e l e g a t e ( I A s y n c R e s u l t   r )  
 	 	 	 	 	 	 	 	 {  
 	 	 	 	 	 	 	 	 	 m r e . S e t ( ) ;  
 	 	 	 	 	 	 	 	 	 e . C a n c e l   =   t r u e ;  
 	 	 	 	 	 	 	 	 } ) ,   n u l l ) ;  
 	 	 	 	 	 	 	 }  
 	 	 	 	 	 	 	 c a t c h  
 	 	 	 	 	 	 	 {  
 	 	 	 	 	 	 	 } ;  
 	 	 	 	 	 	 } ) ;  
 " @   } )  
  
 	 	 	 	 	 	 p o w e r s h e l l . R u n s p a c e   =   m y R u n S p a c e ;  
 	 	 	 	 	 	 p o w e r s h e l l . S t r e a m s . E r r o r . D a t a A d d e d   + =   n e w   E v e n t H a n d l e r < D a t a A d d e d E v e n t A r g s > ( d e l e g a t e ( o b j e c t   s e n d e r ,   D a t a A d d e d E v e n t A r g s   e )  
 	 	 	 	 	 	 {  
 	 	 	 	 	 	 	 u i . W r i t e E r r o r L i n e ( ( ( P S D a t a C o l l e c t i o n < E r r o r R e c o r d > ) s e n d e r ) [ e . I n d e x ] . T o S t r i n g ( ) ) ;  
 	 	 	 	 	 	 } ) ;  
  
 	 	 	 	 	 	 P S D a t a C o l l e c t i o n < s t r i n g >   c o l I n p u t   =   n e w   P S D a t a C o l l e c t i o n < s t r i n g > ( ) ;  
 $ ( i f   ( ! $ r u n t i m e 2 0 )   { @ "  
 	 	 	 	 	 	 i f   ( C o n s o l e I n f o . I s I n p u t R e d i r e c t e d ( ) )  
 	 	 	 	 	 	 {   / /   r e a d   s t a n d a r d   i n p u t  
 	 	 	 	 	 	 	 s t r i n g   s I t e m   =   " " ;  
 	 	 	 	 	 	 	 w h i l e   ( ( s I t e m   =   C o n s o l e . R e a d L i n e ( ) )   ! =   n u l l )  
 	 	 	 	 	 	 	 {   / /   a d d   t o   p o w e r s h e l l   p i p e l i n e  
 	 	 	 	 	 	 	 	 c o l I n p u t . A d d ( s I t e m ) ;  
 	 	 	 	 	 	 	 }  
 	 	 	 	 	 	 }  
 " @   } )  
 	 	 	 	 	 	 c o l I n p u t . C o m p l e t e ( ) ;  
  
 	 	 	 	 	 	 P S D a t a C o l l e c t i o n < P S O b j e c t >   c o l O u t p u t   =   n e w   P S D a t a C o l l e c t i o n < P S O b j e c t > ( ) ;  
 	 	 	 	 	 	 c o l O u t p u t . D a t a A d d e d   + =   n e w   E v e n t H a n d l e r < D a t a A d d e d E v e n t A r g s > ( d e l e g a t e ( o b j e c t   s e n d e r ,   D a t a A d d e d E v e n t A r g s   e )  
 	 	 	 	 	 	 {  
 	 	 	 	 	 	 	 u i . W r i t e L i n e ( c o l O u t p u t [ e . I n d e x ] . T o S t r i n g ( ) ) ;  
 	 	 	 	 	 	 } ) ;  
  
 	 	 	 	 	 	 i n t   s e p a r a t o r   =   0 ;  
 	 	 	 	 	 	 i n t   i d x   =   0 ;  
 	 	 	 	 	 	 f o r e a c h   ( s t r i n g   s   i n   a r g s )  
 	 	 	 	 	 	 {  
 	 	 	 	 	 	 	 i f   ( s t r i n g . C o m p a r e ( s ,   " - w a i t " ,   t r u e )   = =   0 )  
 	 	 	 	 	 	 	 	 p a r a m W a i t   =   t r u e ;  
 	 	 	 	 	 	 	 e l s e   i f   ( s . S t a r t s W i t h ( " - e x t r a c t " ,   S t r i n g C o m p a r i s o n . I n v a r i a n t C u l t u r e I g n o r e C a s e ) )  
 	 	 	 	 	 	 	 {  
 	 	 	 	 	 	 	 	 s t r i n g [ ]   s 1   =   s . S p l i t ( n e w   s t r i n g [ ]   {   " : "   } ,   2 ,   S t r i n g S p l i t O p t i o n s . R e m o v e E m p t y E n t r i e s ) ;  
 	 	 	 	 	 	 	 	 i f   ( s 1 . L e n g t h   ! =   2 )  
 	 	 	 	 	 	 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 	 	 	 	 	 	 C o n s o l e . W r i t e L i n e ( " I f   y o u   s p e c i f y   t h e   - e x t r a c t   o p t i o n   y o u   n e e d   t o   a d d   a   f i l e   f o r   e x t r a c t i o n   i n   t h i s   w a y \ r \ n       - e x t r a c t : \ " < f i l e n a m e > \ " " ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 	 	 	 	 	 	 M e s s a g e B o x . S h o w ( " I f   y o u   s p e c i f y   t h e   - e x t r a c t   o p t i o n   y o u   n e e d   t o   a d d   a   f i l e   f o r   e x t r a c t i o n   i n   t h i s   w a y \ r \ n       - e x t r a c t : \ " < f i l e n a m e > \ " " ,   S y s t e m . A p p D o m a i n . C u r r e n t D o m a i n . F r i e n d l y N a m e ,   M e s s a g e B o x B u t t o n s . O K ,   M e s s a g e B o x I c o n . E r r o r ) ;  
 " @   } )  
 	 	 	 	 	 	 	 	 	 r e t u r n   1 ;  
 	 	 	 	 	 	 	 	 }  
 	 	 	 	 	 	 	 	 e x t r a c t F N   =   s 1 [ 1 ] . T r i m ( n e w   c h a r [ ]   {   ' \ " '   } ) ;  
 	 	 	 	 	 	 	 }  
 	 	 	 	 	 	 	 e l s e   i f   ( s t r i n g . C o m p a r e ( s ,   " - e n d " ,   t r u e )   = =   0 )  
 	 	 	 	 	 	 	 {  
 	 	 	 	 	 	 	 	 s e p a r a t o r   =   i d x   +   1 ;  
 	 	 	 	 	 	 	 	 b r e a k ;  
 	 	 	 	 	 	 	 }  
 	 	 	 	 	 	 	 e l s e   i f   ( s t r i n g . C o m p a r e ( s ,   " - d e b u g " ,   t r u e )   = =   0 )  
 	 	 	 	 	 	 	 {  
 	 	 	 	 	 	 	 	 S y s t e m . D i a g n o s t i c s . D e b u g g e r . L a u n c h ( ) ;  
 	 	 	 	 	 	 	 	 b r e a k ;  
 	 	 	 	 	 	 	 }  
 	 	 	 	 	 	 	 i d x + + ;  
 	 	 	 	 	 	 }  
  
 	 	 	 	 	 	 s t r i n g   s c r i p t   =   S y s t e m . T e x t . E n c o d i n g . U T F 8 . G e t S t r i n g ( S y s t e m . C o n v e r t . F r o m B a s e 6 4 S t r i n g ( @ " $ ( $ s c r i p t ) " ) ) ;  
  
 	 	 	 	 	 	 i f   ( ! s t r i n g . I s N u l l O r E m p t y ( e x t r a c t F N ) )  
 	 	 	 	 	 	 {  
 	 	 	 	 	 	 	 S y s t e m . I O . F i l e . W r i t e A l l T e x t ( e x t r a c t F N ,   s c r i p t ) ;  
 	 	 	 	 	 	 	 r e t u r n   0 ;  
 	 	 	 	 	 	 }  
  
 	 	 	 	 	 	 p o w e r s h e l l . A d d S c r i p t ( s c r i p t ) ;  
  
 	 	 	 	 	 	 / /   p a r s e   p a r a m e t e r s  
 	 	 	 	 	 	 s t r i n g   a r g b u f f e r   =   n u l l ;  
 	 	 	 	 	 	 / /   r e g e x   f o r   n a m e d   p a r a m e t e r s  
 	 	 	 	 	 	 S y s t e m . T e x t . R e g u l a r E x p r e s s i o n s . R e g e x   r e g e x   =   n e w   S y s t e m . T e x t . R e g u l a r E x p r e s s i o n s . R e g e x ( @ " ^ - ( [ ^ :   ] + ) [   : ] ? ( [ ^ : ] * ) $ " ) ;  
  
 	 	 	 	 	 	 f o r   ( i n t   i   =   s e p a r a t o r ;   i   <   a r g s . L e n g t h ;   i + + )  
 	 	 	 	 	 	 {  
 	 	 	 	 	 	 	 S y s t e m . T e x t . R e g u l a r E x p r e s s i o n s . M a t c h   m a t c h   =   r e g e x . M a t c h ( a r g s [ i ] ) ;  
 	 	 	 	 	 	 	 i f   ( m a t c h . S u c c e s s   & &   m a t c h . G r o u p s . C o u n t   = =   3 )  
 	 	 	 	 	 	 	 {   / /   p a r a m e t e r   i n   p o w e r s h e l l   s t y l e ,   m e a n s   n a m e d   p a r a m e t e r   f o u n d  
 	 	 	 	 	 	 	 	 i f   ( a r g b u f f e r   ! =   n u l l )   / /   a l r e a d y   a   n a m e d   p a r a m e t e r   i n   b u f f e r ,   t h e n   f l u s h   i t  
 	 	 	 	 	 	 	 	 	 p o w e r s h e l l . A d d P a r a m e t e r ( a r g b u f f e r ) ;  
  
 	 	 	 	 	 	 	 	 i f   ( m a t c h . G r o u p s [ 2 ] . V a l u e . T r i m ( )   = =   " " )  
 	 	 	 	 	 	 	 	 {   / /   s t o r e   n a m e d   p a r a m e t e r   i n   b u f f e r  
 	 	 	 	 	 	 	 	 	 a r g b u f f e r   =   m a t c h . G r o u p s [ 1 ] . V a l u e ;  
 	 	 	 	 	 	 	 	 }  
 	 	 	 	 	 	 	 	 e l s e  
 	 	 	 	 	 	 	 	 	 / /   c a u t i o n :   w h e n   c a l l e d   i n   p o w e r s h e l l   $ T R U E   g e t s   c o n v e r t e d ,   w h e n   c a l l e d   i n   c m d . e x e   n o t  
 	 	 	 	 	 	 	 	 	 i f   ( ( m a t c h . G r o u p s [ 2 ] . V a l u e   = =   " $ T R U E " )   | |   ( m a t c h . G r o u p s [ 2 ] . V a l u e . T o U p p e r ( )   = =   " \ x 2 4 T R U E " ) )  
 	 	 	 	 	 	 	 	 	 {   / /   s w i t c h   f o u n d  
 	 	 	 	 	 	 	 	 	 	 p o w e r s h e l l . A d d P a r a m e t e r ( m a t c h . G r o u p s [ 1 ] . V a l u e ,   t r u e ) ;  
 	 	 	 	 	 	 	 	 	 	 a r g b u f f e r   =   n u l l ;  
 	 	 	 	 	 	 	 	 	 }  
 	 	 	 	 	 	 	 	 	 e l s e  
 	 	 	 	 	 	 	 	 	 	 / /   c a u t i o n :   w h e n   c a l l e d   i n   p o w e r s h e l l   $ F A L S E   g e t s   c o n v e r t e d ,   w h e n   c a l l e d   i n   c m d . e x e   n o t  
 	 	 	 	 	 	 	 	 	 	 i f   ( ( m a t c h . G r o u p s [ 2 ] . V a l u e   = =   " $ F A L S E " )   | |   ( m a t c h . G r o u p s [ 2 ] . V a l u e . T o U p p e r ( )   = =   " \ x 2 4 " + " F A L S E " ) )  
 	 	 	 	 	 	 	 	 	 	 {   / /   s w i t c h   f o u n d  
 	 	 	 	 	 	 	 	 	 	 	 p o w e r s h e l l . A d d P a r a m e t e r ( m a t c h . G r o u p s [ 1 ] . V a l u e ,   f a l s e ) ;  
 	 	 	 	 	 	 	 	 	 	 	 a r g b u f f e r   =   n u l l ;  
 	 	 	 	 	 	 	 	 	 	 }  
 	 	 	 	 	 	 	 	 	 	 e l s e  
 	 	 	 	 	 	 	 	 	 	 {   / /   n a m e d   p a r a m e t e r   w i t h   v a l u e   f o u n d  
 	 	 	 	 	 	 	 	 	 	 	 p o w e r s h e l l . A d d P a r a m e t e r ( m a t c h . G r o u p s [ 1 ] . V a l u e ,   m a t c h . G r o u p s [ 2 ] . V a l u e ) ;  
 	 	 	 	 	 	 	 	 	 	 	 a r g b u f f e r   =   n u l l ;  
 	 	 	 	 	 	 	 	 	 	 }  
 	 	 	 	 	 	 	 }  
 	 	 	 	 	 	 	 e l s e  
 	 	 	 	 	 	 	 {   / /   u n n a m e d   p a r a m e t e r   f o u n d  
 	 	 	 	 	 	 	 	 i f   ( a r g b u f f e r   ! =   n u l l )  
 	 	 	 	 	 	 	 	 {   / /   a l r e a d y   a   n a m e d   p a r a m e t e r   i n   b u f f e r ,   s o   t h i s   i s   t h e   v a l u e  
 	 	 	 	 	 	 	 	 	 p o w e r s h e l l . A d d P a r a m e t e r ( a r g b u f f e r ,   a r g s [ i ] ) ;  
 	 	 	 	 	 	 	 	 	 a r g b u f f e r   =   n u l l ;  
 	 	 	 	 	 	 	 	 }  
 	 	 	 	 	 	 	 	 e l s e  
 	 	 	 	 	 	 	 	 {   / /   p o s i t i o n   p a r a m e t e r   f o u n d  
 	 	 	 	 	 	 	 	 	 p o w e r s h e l l . A d d A r g u m e n t ( a r g s [ i ] ) ;  
 	 	 	 	 	 	 	 	 }  
 	 	 	 	 	 	 	 }  
 	 	 	 	 	 	 }  
  
 	 	 	 	 	 	 i f   ( a r g b u f f e r   ! =   n u l l )   p o w e r s h e l l . A d d P a r a m e t e r ( a r g b u f f e r ) ;   / /   f l u s h   p a r a m e t e r   b u f f e r . . .  
  
 	 	 	 	 	 	 / /   c o n v e r t   o u t p u t   t o   s t r i n g s  
 	 	 	 	 	 	 p o w e r s h e l l . A d d C o m m a n d ( " o u t - s t r i n g " ) ;  
 	 	 	 	 	 	 / /   w i t h   a   s i n g l e   s t r i n g   p e r   l i n e  
 	 	 	 	 	 	 p o w e r s h e l l . A d d P a r a m e t e r ( " s t r e a m " ) ;  
  
 	 	 	 	 	 	 p o w e r s h e l l . B e g i n I n v o k e < s t r i n g ,   P S O b j e c t > ( c o l I n p u t ,   c o l O u t p u t ,   n u l l ,   n e w   A s y n c C a l l b a c k ( d e l e g a t e ( I A s y n c R e s u l t   a r )  
 	 	 	 	 	 	 {  
 	 	 	 	 	 	 	 i f   ( a r . I s C o m p l e t e d )  
 	 	 	 	 	 	 	 	 m r e . S e t ( ) ;  
 	 	 	 	 	 	 } ) ,   n u l l ) ;  
  
 	 	 	 	 	 	 w h i l e   ( ! m e . S h o u l d E x i t   & &   ! m r e . W a i t O n e ( 1 0 0 ) )  
 	 	 	 	 	 	 {   } ;  
  
 	 	 	 	 	 	 p o w e r s h e l l . S t o p ( ) ;  
  
 	 	 	 	 	 	 i f   ( p o w e r s h e l l . I n v o c a t i o n S t a t e I n f o . S t a t e   = =   P S I n v o c a t i o n S t a t e . F a i l e d )  
 	 	 	 	 	 	 	 u i . W r i t e E r r o r L i n e ( p o w e r s h e l l . I n v o c a t i o n S t a t e I n f o . R e a s o n . M e s s a g e ) ;  
 	 	 	 	 	 }  
  
 	 	 	 	 	 m y R u n S p a c e . C l o s e ( ) ;  
 	 	 	 	 }  
 	 	 	 }  
 	 	 	 c a t c h   ( E x c e p t i o n   e x )  
 	 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 	 C o n s o l e . W r i t e ( " A n   e x c e p t i o n   o c c u r e d :   " ) ;  
 	 	 	 	 C o n s o l e . W r i t e L i n e ( e x . M e s s a g e ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 	 M e s s a g e B o x . S h o w ( " A n   e x c e p t i o n   o c c u r e d :   "   +   e x . M e s s a g e ,   S y s t e m . A p p D o m a i n . C u r r e n t D o m a i n . F r i e n d l y N a m e ,   M e s s a g e B o x B u t t o n s . O K ,   M e s s a g e B o x I c o n . E r r o r ) ;  
 " @   } )  
 	 	 	 }  
  
 	 	 	 i f   ( p a r a m W a i t )  
 	 	 	 {  
 $ ( i f   ( ! $ n o C o n s o l e )   { @ "  
 	 	 	 	 C o n s o l e . W r i t e L i n e ( " H i t   a n y   k e y   t o   e x i t . . . " ) ;  
 	 	 	 	 C o n s o l e . R e a d K e y ( ) ;  
 " @   }   e l s e   { @ "  
 	 	 	 	 M e s s a g e B o x . S h o w ( " C l i c k   O K   t o   e x i t . . . " ,   S y s t e m . A p p D o m a i n . C u r r e n t D o m a i n . F r i e n d l y N a m e ) ;  
 " @   } )  
 	 	 	 }  
 	 	 	 r e t u r n   m e . E x i t C o d e ;  
 	 	 }  
  
 	 	 s t a t i c   v o i d   C u r r e n t D o m a i n _ U n h a n d l e d E x c e p t i o n ( o b j e c t   s e n d e r ,   U n h a n d l e d E x c e p t i o n E v e n t A r g s   e )  
 	 	 {  
 	 	 	 t h r o w   n e w   E x c e p t i o n ( " U n h a n d l e d   e x c e p t i o n   i n   P S 2 E X E " ) ;  
 	 	 }  
 	 }  
 }  
 " @  
 # e n d r e g i o n  
  
 $ c o n f i g F i l e F o r E X E 2   =   " < ? x m l   v e r s i o n = " " 1 . 0 " "   e n c o d i n g = " " u t f - 8 " "   ? > ` r ` n < c o n f i g u r a t i o n > < s t a r t u p > < s u p p o r t e d R u n t i m e   v e r s i o n = " " v 2 . 0 . 5 0 7 2 7 " " / > < / s t a r t u p > < / c o n f i g u r a t i o n > "  
 $ c o n f i g F i l e F o r E X E 3   =   " < ? x m l   v e r s i o n = " " 1 . 0 " "   e n c o d i n g = " " u t f - 8 " "   ? > ` r ` n < c o n f i g u r a t i o n > < s t a r t u p > < s u p p o r t e d R u n t i m e   v e r s i o n = " " v 4 . 0 " "   s k u = " " . N E T F r a m e w o r k , V e r s i o n = v 4 . 0 " "   / > < / s t a r t u p > < / c o n f i g u r a t i o n > "  
  
 W r i t e - H o s t   " C o m p i l i n g   f i l e . . .   "   - N o N e w l i n e  
 $ c o m p i l e r   =   $ c o p . C r e a t e C o m p i l e r ( )  
 $ c r   =   $ c o m p i l e r . C o m p i l e A s s e m b l y F r o m S o u r c e ( $ c p ,   $ p r o g r a m F r a m e )  
 i f   ( $ c r . E r r o r s . C o u n t   - g t   0 )  
 {  
 	 W r i t e - H o s t   " "  
 	 W r i t e - H o s t   " "  
 	 i f   ( T e s t - P a t h   $ o u t p u t F i l e )  
 	 {  
 	 	 R e m o v e - I t e m   $ o u t p u t F i l e   - V e r b o s e : $ F A L S E  
 	 }  
 	 W r i t e - H o s t   - F o r e g r o u n d C o l o r   r e d   " C o u l d   n o t   c r e a t e   t h e   P o w e r S h e l l   . e x e   f i l e   b e c a u s e   o f   c o m p i l a t i o n   e r r o r s .   U s e   - v e r b o s e   p a r a m e t e r   t o   s e e   d e t a i l s . "  
 	 $ c r . E r r o r s   |   %   {   W r i t e - V e r b o s e   $ _   - V e r b o s e : $ v e r b o s e }  
 }  
 e l s e  
 {  
 	 W r i t e - H o s t   " "  
 	 W r i t e - H o s t   " "  
 	 i f   ( T e s t - P a t h   $ o u t p u t F i l e )  
 	 {  
 	 	 W r i t e - H o s t   " O u t p u t   f i l e   "   - N o N e w l i n e  
 	 	 W r i t e - H o s t   $ o u t p u t F i l e   - N o N e w l i n e  
 	 	 W r i t e - H o s t   "   w r i t t e n "  
  
 	 	 i f   ( $ d e b u g )  
 	 	 {  
 	 	 	 $ c r . T e m p F i l e s   |   ?   {   $ _   - i l i k e   " * . c s "   }   |   s e l e c t   - f i r s t   1   |   %   {  
 	 	 	 	 $ d s t S r c   =   ( [ S y s t e m . I O . P a t h ] : : C o m b i n e ( [ S y s t e m . I O . P a t h ] : : G e t D i r e c t o r y N a m e ( $ o u t p u t F i l e ) ,   [ S y s t e m . I O . P a t h ] : : G e t F i l e N a m e W i t h o u t E x t e n s i o n ( $ o u t p u t F i l e ) + " . c s " ) )  
 	 	 	 	 W r i t e - H o s t   " S o u r c e   f i l e   n a m e   f o r   d e b u g   c o p i e d :   $ ( $ d s t S r c ) "  
 	 	 	 	 C o p y - I t e m   - P a t h   $ _   - D e s t i n a t i o n   $ d s t S r c   - F o r c e  
 	 	 	 }  
 	 	 	 $ c r . T e m p F i l e s   |   R e m o v e - I t e m   - V e r b o s e : $ F A L S E   - F o r c e   - E r r o r A c t i o n   S i l e n t l y C o n t i n u e  
 	 	 }  
 	 	 i f   ( ! $ n o C o n f i g f i l e )  
 	 	 {  
 	 	 	 i f   ( $ r u n t i m e 2 0 )  
 	 	 	 {  
 	 	 	 	 $ c o n f i g F i l e F o r E X E 2   |   S e t - C o n t e n t   ( $ o u t p u t F i l e + " . c o n f i g " )   - E n c o d i n g   U T F 8  
 	 	 	 	 W r i t e - H o s t   " C o n f i g   f i l e   f o r   E X E   c r e a t e d . "  
 	 	 	 }  
 	 	 	 i f   ( $ r u n t i m e 4 0 )  
 	 	 	 {  
 	 	 	 	 $ c o n f i g F i l e F o r E X E 3   |   S e t - C o n t e n t   ( $ o u t p u t F i l e + " . c o n f i g " )   - E n c o d i n g   U T F 8  
 	 	 	 	 W r i t e - H o s t   " C o n f i g   f i l e   f o r   E X E   c r e a t e d . "  
 	 	 	 }  
 	 	 }  
 	 }  
 	 e l s e  
 	 {  
 	 	 W r i t e - H o s t   " O u t p u t   f i l e   "   - N o N e w l i n e   - F o r e g r o u n d C o l o r   R e d  
 	 	 W r i t e - H o s t   $ o u t p u t F i l e   - F o r e g r o u n d C o l o r   R e d   - N o N e w l i n e  
 	 	 W r i t e - H o s t   "   n o t   w r i t t e n "   - F o r e g r o u n d C o l o r   R e d  
 	 }  
 }  
  
 i f   ( $ r e q u i r e A d m i n )  
 {    
         i f   ( T e s t - P a t h   $ ( $ o u t p u t F i l e + " . w i n 3 2 m a n i f e s t " ) )  
 	 {  
 	 	 R e m o v e - I t e m   $ ( $ o u t p u t F i l e + " . w i n 3 2 m a n i f e s t " )   - V e r b o s e : $ F A L S E  
 	 }  
 }  
 