package mods.ultimate_records;
/** Pure viewport fitting, independent of the host UI's translation and scale. */
class RecLayout {
 public static function fit(bx:Float,by:Float,bw:Float,bh:Float,vx:Float,vy:Float,vw:Float,vh:Float,maximum:Float):{x:Float,y:Float,scale:Float}{
  var margin=Math.min(16.,Math.min(vw,vh)*.04);
  var scale=Math.max(.001,Math.min(maximum,Math.min(Math.max(1.,vw-margin*2)/bw,Math.max(1.,vh-margin*2)/bh)));
  return {x:vx+vw/2-(bx+bw/2)*scale,y:vy+vh/2-(by+bh/2)*scale,scale:scale};
 }
}
