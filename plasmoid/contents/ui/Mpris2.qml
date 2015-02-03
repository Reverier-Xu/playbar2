/*
 *   Author: audoban <audoban@openmailbox.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.4
import org.kde.plasma.core 2.0 as PlasmaCore
import "plasmapackage:/code/utils.js" as Utils

PlasmaCore.DataSource{
	id: mpris2

	engine: 'mpris2'

	interval: minimumLoad

	readonly property int maximumLoad: 500

	readonly property int minimumLoad: 1500

	readonly property bool isMaximumLoad: interval == maximumLoad

	readonly property bool sourceActive: source.length > 0


	property string previousSource

	property alias source: mpris2.connectedSources


	property var service: null


	property string identity: hasSource('Identity') ? data[source]['Identity'] : i18n("no_source")

	property string playbackStatus: hasSource('PlaybackStatus') ? data[source]['PlaybackStatus'] : "Paused"

	property string artUrl: hasMetadataMpris('artUrl') ? data[source]['Metadata']['mpris:artUrl'] : ""

	property string artist: hasMetadata('artist') ? data[source]['Metadata']['xesam:artist'].toString() : ""

	property string album: hasMetadata('album') ? data[source]['Metadata']['xesam:album'] : ""

	property string title: hasMetadata('title') ? data[source]['Metadata']['xesam:title'] : ""

// 	hundredth of second
	property int length: hasMetadataMpris('length') ? data[source]['Metadata']['mpris:length'] / 10000: 0
// 	hundredth of second
	property int position: 0

	property real userRating: 0

	property real volume: hasSource('Volume') ? data[source]['Volume'] : 0


	property bool canControl: hasSource('CanControl') ? data[source]['CanControl'] : false

	property bool canGoNext: hasSource('CanGoNext') ? data[source]['CanGoNext'] : false

	property bool canGoPrevious: hasSource('CanGoPrevious') ? data[source]['CanGoPrevious'] : false

	property bool canSeek: hasSource('CanSeek') ? data[source]['CanSeek'] : false

	property bool canRaise: hasSource('CanRaise') ? data[source]['CanRaise'] : false


	Component.onCompleted: nextSource()

	onIdentityChanged: Utils.setActions(source[0], identity)

	onNewData: {
		if(isMaximumLoad)
			position = data['Position'] / 10000
	}

	onSourcesChanged: {
		if(connectedSources.length === 0) nextSource()
	}

	onSourceAdded: {
		debug("Source added: " + source)
		debug("sources: "+ sources)

		if(source != '@multiplex' && connectedSources.length == 0) {
			connectSource(source)
		}
	}

	onSourceRemoved: {
		if(source == previousSource) {
			nextSource()
		}
	}

	onSourceConnected: {
		setService(source)
		debug("Source connected: "+source)
		debug("valid engine: "+ valid)
	}

	onSourceDisconnected: {
		setService(null)
		previousSource = source
		debug("disconnected: "+source)
	}

	onConnectedSourcesChanged: { setService(source[0]) }

	function hasMetadata(key){
		return data[source[0]] != undefined
			&& data[source[0]]['Metadata'] != undefined
			&& data[source[0]]['Metadata']['xesam:'+key] != undefined
	}

	function hasMetadataMpris(key){
		return data[source[0]] != undefined
		&& data[source[0]]['Metadata'] != undefined
		&& data[source[0]]['Metadata']['mpris:'+key] != undefined
	}

	function hasSource(key){
		return data[source[0]] != undefined
			&& data[source[0]][key] != undefined
	}

	function nextSource(){
		debug("nextSource()")
		for(var i = 0; i < sources.length; i++){
			if(connectedSources[0] == sources[i] || connectedSources == [""] || connectedSources == "")
			{
				if(++i < sources.length && sources[i] != '@multiplex'){
					disconnectSource(source[0])
					connectSource(sources[i])
				}else if(++i < sources.length){
					disconnectSource(source[0])
					connectSource(sources[i])
				}else if(sources[0] != '@multiplex') {
					disconnectSource(source[0])
					connectSource(sources[0])
				}
				return
			}
		}
	}

	function setService(source){
		if(!source) service = null
		service = mpris2.serviceForSource(source)
		debug("service active" + service != null)
	}

	function seek(position, currentPosition){
		if(service && canControl && canSeek) {
			var job = service.operationDescription('SetPosition')
			job['microseconds'] = (position * 10000).toFixed(0)
			service.startOperationCall(job)
		}
		return position
// 			if(source == 'clementine') {
// 				job = service.operationDescription('Seek')
// 				job['microseconds'] = ((-currentPosition + position) * 10000).toFixed(0)
// 				service.startOperationCall(job)
// 				return
// 			}
	}

	function startOperation(name){
		if(service && canControl){
			var job = service.operationDescription(name)
			service.startOperationCall(job)
		}
	}

	function setVolume(value){
		if(service && canControl && service.isOperationEnabled('SetVolume')){
			debug(value.toString())
			var job = service.operationDescription('SetVolume')
			job['level'] = value
			service.startOperationCall(job)
			value = value < 0 ? 0 : value
			value = value > 1.2 ? 1 : value
		}
		return value
	}
}
